# PROJECT USING AI CHAT WITH SQL 

## **Project Structure**
```
project
├── data
│   ├── sqldb.db
│   └── sql
│       ├── sqlite.sql
│       ├── postgre.sql
│       ├── mysql.sql
├── notebook
│   ├── Chat_two_db.ipynb
│   └── Chat_SQLite_one_db.ipynb
├── src
│   ├── app.py
│   ├── app_kernel.py
│   └── app_call_tool.py
├── .env
├── db_config.json
├── requirements.txt
```

## **Description**
This project uses Streamlit to build a web-based interface for interacting with an Multiple database. The project includes SQL scripts, Jupyter notebooks for data exploration, and Python modules for the application logic.

## **Setup and Deployment**

### **1. Environment Setup**
1. **Install Python**:
   Ensure you have Python 3.9.x or later installed on your system.

2. **Create a Virtual Environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Linux/MacOS
   venv\Scripts\activate   # On Windows
   ```

3. **Install Required Packages**:
   ```bash
   pip install -r requirements.txt
   ```

### **2. Configure Environment Variables**
1. Create a `.env` file in the root directory.
2. Add necessary environment variables (e.g., database paths or API keys).

### **3. Database Setup**
1. Ensure `sqldb.db` exists in the `data` folder.
2. Verify SQL scripts in `data/sql` are valid and contain the necessary commands.
   - `sqlite.sql`: Script for creating tables on the SQLite server.
   - `postgre.sql`: Script for populating tables on the PostgreSQL server.
   - `mysql.sql`: Script for executing predefined queries on the MySQL server.

### **4. Run Notebooks (Optional)**
1. Open Jupyter Notebook.
2. Explore and validate functionality using:
   - `Chat_two_db.ipynb`
   - `Chat_SQLite_one_db.ipynb`

### **5. Launch the Application**
1. Navigate to the `src` directory:
   ```bash
   cd src
   ```

2. Run the Streamlit application:
   ```bash
   streamlit run app.py/ app_call_tool.py/ app_kernel.py
   ```


### **6. Deployment to a Server (Optional)**
1. Upload the project to your preferred server platform (e.g., AWS, GCP, Heroku, Streamlit).
2. Install required dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Configure environment variables on the server.
4. Run the Streamlit application on the server.

## **Key Files**
- **`data/sqldb.db`**: SQLite database.
- **`data/sql/`**: SQL scripts for database setup and operations.
- **`notebook/`**: Jupyter notebooks for exploratory data analysis.
- **`src/app.py`**: Main file to launch the Streamlit interface.
- **`.env`**: Contains environment variables (e.g., database configurations).
- **`requirements.txt`**: Lists all Python dependencies.

## **Requirements**
- Python 3.9+
- Streamlit
- SQLite/ MySQL/ PostgreSQL
- Any additional libraries listed in `requirements.txt`

## **Contributors**
- **Hàng Tuấn Kiệt**
- **Huỳnh Thị Hạnh Nguyên**
- **Nguyễn Tấn Lập**
- **Trần Minh Tâm**

---


