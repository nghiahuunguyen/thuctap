import json
import urllib

import psycopg2
import streamlit as st
from dotenv import load_dotenv
from langchain_community.utilities import SQLDatabase
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
from langchain_openai import AzureChatOpenAI
import os
# import psycopg2
# import urllib.parse

# Load environment variables for Azure OpenAI
load_dotenv()

def load_config():
    with open("db_config.json", "r") as f:
        return json.load(f)

def get_llm():
    return AzureChatOpenAI(
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        azure_deployment=os.getenv("AZURE_OPENAI_DEPLOYMENT"),
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
        temperature=0,
        max_tokens=None,
        timeout=None,
        max_retries=2
    )

# Hàm kiểm tra kết nối PostgreSQL
def test_postgresql_connection(config):
    database_url = f"postgresql://{config['user']}:{config['password']}@{config['host']}:{config['port']}/{config['database']}?sslmode=require"
    try:
        connection = psycopg2.connect(database_url)
        print("Kết nối PostgreSQL thành công!")
        return connection
    except psycopg2.OperationalError as e:
        print(f"Lỗi kết nối: {e}")
        return None


def init_mysql(config):
    user = urllib.parse.quote_plus(config['user'])
    password = urllib.parse.quote_plus(config['password'])
    host = config['host']
    port = config['port']
    database = config['database']

    db_uri = f"mysql+pymysql://{user}:{password}@{host}:{port}/{database}"
    print(db_uri)
    return SQLDatabase.from_uri(db_uri)

def init_postgresql(config):
    # Kiểm tra kết nối PostgreSQL
    conn = test_postgresql_connection(config["postgresql"])
    if conn is not None:
        db_uri = f"postgresql://{config['postgresql']['user']}:{config['postgresql']['password']}@{config['postgresql']['host']}:{config['postgresql']['port']}/{config['postgresql']['database']}"
        return SQLDatabase.from_uri(db_uri)
    else:
        raise Exception("Failed to connect to PostgreSQL.")

def init_sqlite(config):
    db_uri = f"sqlite:///{config['path']}"
    return SQLDatabase.from_uri(db_uri)

def init_database(db_type, config):
    if db_type == "mysql":
        return init_mysql(config["mysql"])
    elif db_type == "postgresql":
        return init_postgresql(config)
    elif db_type == "sqlite":
        return init_sqlite(config["sqlite"])
    else:
        raise ValueError("Unsupported database type")

def get_sql_chain(db, question):
    template = """
    You are a data analyst at a company. You are interacting with a user who is asking you questions about the company's database.
    Based on the table schema below, write a SQL query that would answer the user's question. Take the conversation history into account.

    <SCHEMA>{schema}</SCHEMA>

    Conversation History: {chat_history}

    Write only the SQL query and nothing else. Do not wrap the SQL query in any other text, not even backticks.

    For example:
    Question: which 3 artists have the most tracks?
    SQL Query: SELECT ArtistId, COUNT(*) as track_count FROM Track GROUP BY ArtistId ORDER BY track_count DESC LIMIT 3;
    Question: Name 10 artists
    SQL Query: SELECT Name FROM Artist LIMIT 10;

    Your turn:

    Question: {question}
    SQL Query:
    """

    prompt = ChatPromptTemplate.from_template(template)
    llm = get_llm()

    def get_schema(_):
        return db.get_table_info()

    return (
        RunnablePassthrough.assign(schema=get_schema)
        | prompt
        | llm
        | StrOutputParser()
    )

def get_response(user_query, db, chat_history):
    sql_chain = get_sql_chain(db, user_query)

    template = """
    You are a data analyst at a company. You are interacting with a user who is asking you questions about the company's database.
    Based on the table schema below, question, sql query, and sql response, write a natural language response.
    <SCHEMA>{schema}</SCHEMA>

    Conversation History: {chat_history}
    SQL Query: <SQL>{query}</SQL>
    User question: {question}
    SQL Response: {response}"""

    prompt = ChatPromptTemplate.from_template(template)
    llm = get_llm()

    chain = (
        RunnablePassthrough.assign(query=sql_chain).assign(
            schema=lambda _: db.get_table_info(),
            response=lambda vars: db.run(vars["query"]),
        )
        | prompt
        | llm
        | StrOutputParser()
    )

    return chain.invoke({
        "question": user_query,
        "chat_history": chat_history,
    })

# Main UI
st.title("Chat with Multiple Databases")

# Sidebar configuration
with st.sidebar:
    st.subheader("Settings")
    st.write("Choose a database to connect to:")

    db_type = st.selectbox("Select Database", ["mysql", "postgresql", "sqlite"])

    if st.button("Connect"):
        try:
            config = load_config()
            db = init_database(db_type, config)
            st.session_state.db = db
            st.success(f"Connected to {db_type} database!")
        except Exception as e:
            st.error(f"Failed to connect: {str(e)}")

# Chat interface
if "db" in st.session_state:
    if "chat_history" not in st.session_state:
        st.session_state.chat_history = [
            AIMessage(content="Hello! I'm here to help with SQL queries.")
        ]

    # Display chat history
    for message in st.session_state.chat_history:
        if isinstance(message, AIMessage):
            with st.chat_message("AI"):
                st.markdown(message.content)
        elif isinstance(message, HumanMessage):
            with st.chat_message("Human"):
                st.markdown(message.content)

    user_query = st.chat_input("Ask a question about the database...")
    if user_query is not None and user_query.strip() != "":
        st.session_state.chat_history.append(HumanMessage(content=user_query))

        with st.chat_message("Human"):
            st.markdown(user_query)

        with st.chat_message("AI"):
            try:
                response = get_response(user_query, st.session_state.db, st.session_state.chat_history)
                st.markdown(response)
                st.session_state.chat_history.append(AIMessage(content=response))
            except Exception as e:
                error_message = f"Error processing query: {str(e)}"
                st.error(error_message)
                st.session_state.chat_history.append(AIMessage(content=error_message))

else:
    st.info("Please connect to a database using the sidebar first.")
