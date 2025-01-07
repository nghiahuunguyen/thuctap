import urllib

from dotenv import load_dotenv
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_community.utilities import SQLDatabase
from langchain_core.output_parsers import StrOutputParser
from langchain_openai import AzureChatOpenAI
import streamlit as st
import os

# Load environment variables
load_dotenv()

# Validate Azure OpenAI configuration
if not all([os.getenv('AZURE_OPENAI_ENDPOINT'),
           os.getenv('AZURE_OPENAI_API_KEY'),
           os.getenv('AZURE_OPENAI_API_VERSION')]):
    raise ValueError("Missing Azure OpenAI configuration. Please check your .env file.")

# Initialize Streamlit page configuration
st.set_page_config(page_title="Chat with Multiple Databases", page_icon=":speech_balloon:")

# Database configurations (3 databases)
DATABASES = {
    "MySQL": "mysql+pymysql://root:{password}@35.198.228.62:3306/cost_central_monitor".format(
        password=urllib.parse.quote_plus('UP?_]sBRY42@=)=;')
    ),
    "PostgreSQL": "postgresql://postgres:N~s~sh?]r{DY6.8D@35.247.174.112:5432/cost_central_monitor?sslmode=require"
}

# Initialize session state
if "chat_history" not in st.session_state:
    st.session_state.chat_history = [
        AIMessage(content="Hello! I'm a SQL assistant. I can query multiple databases for you."),
    ]
if "db_instances" not in st.session_state:
    st.session_state.db_instances = {name: SQLDatabase.from_uri(uri) for name, uri in DATABASES.items()}

# Get LLM model
def get_llm():
    return AzureChatOpenAI(
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        azure_deployment=os.getenv("AZURE_OPENAI_DEPLOYMENT"),
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
        temperature=0,
    )

# Define Semantic Kernel function to select relevant databases
from semantic_kernel import Kernel
from semantic_kernel.functions.kernel_function_decorator import kernel_function

@kernel_function(name="Choose databases", description="Choose relevant databases for the query")
def select_databases(user_query, db_schemas):
    """
    This function uses the Kernel to select relevant databases for the user query.
    The result will be a list of database names.
    """
    llm = get_llm()
    schemas_context = "\n".join([f"{name}: {schema}" for name, schema in db_schemas.items()])
    
    # Cập nhật prompt để yêu cầu danh sách cơ sở dữ liệu phù hợp
    prompt = f"""
    Here are the schemas of the available databases:
    {schemas_context}

    User query: {user_query}

    Please return a comma-separated list of database names that are most relevant for the question. 
    Do not include any explanations or extra text, just the names of the databases.
    """
    
    # Truyền chuỗi vào invoke() và lấy kết quả
    result = llm.invoke(prompt)
    
    # Trả về danh sách cơ sở dữ liệu sau khi tách chuỗi
    return [db.strip() for db in result.content.strip().split(',')]

# SQL Chain for a specific database
def get_sql_chain(db):
    template = """
    You are a data analyst at a company. You are interacting with a user who is asking you questions about the company's database.
    Based on the table schema below, write a SQL query that would answer the user's question. Take the conversation history into account.

    <SCHEMA>{schema}</SCHEMA>

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

# Generate SQL and query multiple databases
def query_multiple_databases_with_ai(user_query, db_instances):
    # Step 1: Get schemas from all databases
    db_schemas = {name: db.get_table_info() for name, db in db_instances.items()}

    # Step 2: Use LLM to select the most relevant databases
    selected_db_names = select_databases(user_query, db_schemas)
    
    # Step 3: Generate SQL and fetch results for each selected database
    results = []
    for db_name in selected_db_names:
        db_name = db_name.strip()
        selected_db = db_instances.get(db_name)
        if selected_db:
            schema = selected_db.get_table_info()
            sql_query = get_sql_chain(selected_db).invoke({"question": user_query})
            raw_results = selected_db.run(sql_query)
            processed_results = process_results_with_ai(raw_results, user_query)
            results.append((db_name, processed_results))
    
    return results

def process_results_with_ai(raw_results, user_query):
    llm = get_llm()
    prompt = f"Here are the results from the query: {user_query}. Format the results nicely:\n{raw_results}"

    # Gọi LLM để trả về câu SQL mà không có giải thích
    result = llm.invoke(prompt)  # Invoke trả về đối tượng AIMessage
    return result.content.strip()  # Lấy nội dung (content) của AIMessage và gọi strip()

# Streamlit UI
st.title("Chat with Multiple Databases")

if st.button("Connect to Databases"):
    with st.spinner("Initializing database connections..."):
        try:
            st.session_state.db_instances = {name: SQLDatabase.from_uri(uri) for name, uri in DATABASES.items()}
            st.success("Connected to all databases!")
        except Exception as e:
            st.error(f"Failed to initialize database connections: {str(e)}")

# Chat interface
if st.session_state.db_instances:
    for message in st.session_state.chat_history:
        if isinstance(message, AIMessage):
            with st.chat_message("AI"):
                st.markdown(message.content)
        elif isinstance(message, HumanMessage):
            with st.chat_message("Human"):
                st.markdown(message.content)

    user_query = st.chat_input("Ask a database question...")
    if user_query:
        st.session_state.chat_history.append(HumanMessage(content=user_query))
        with st.chat_message("Human"):
            st.markdown(user_query)

        with st.chat_message("AI"):
            try:
                results = query_multiple_databases_with_ai(user_query, st.session_state.db_instances)
                response = ""
                for db_name, processed_results in results:
                    response += f"**Database: {db_name}**\n{processed_results}\n\n"
                st.markdown(response)
                st.session_state.chat_history.append(AIMessage(content=response))
            except Exception as e:
                error_message = f"Error: {str(e)}"
                st.error(error_message)
                st.session_state.chat_history.append(AIMessage(content=error_message))
else:
    st.info("Please initialize databases first.")
