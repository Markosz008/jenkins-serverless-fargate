from flask import Flask, render_template, request
import mysql.connector
import os
import socket
import time

app = Flask(__name__)

# Adatbázis adatok az AWS-ből
def get_db_connection():
    raw_host = os.environ.get('DB_HOST')
    host_only = raw_host.split(':')[0] if raw_host else None
    
    return mysql.connector.connect(
        host=host_only,
        port=3306,
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASS'),
        database=os.environ.get('DB_NAME')
    )

def init_db():
    print("Adatbázis inicializálása...")
    retries = 5
    while retries > 0:
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS messages (
                    id INT AUTO_INCREMENT PRIMARY KEY, 
                    content TEXT
                )
            ''')
            conn.commit()
            cursor.close()
            conn.close()
            print("Adatbázis tábla rendben.")
            break
        except Exception as e:
            print(f"Hiba az inicializáláskor (még {retries} próbálkozás): {e}")
            retries -= 1
            time.sleep(5)

@app.route('/')
def index():
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT content FROM messages ORDER BY id DESC')
        messages = cursor.fetchall()
        cursor.close()
        conn.close()
    except Exception as e:
        return f"<h1>Adatbázis hiba!</h1><p>{str(e)}</p>"
    
    return f"""
    <html>
    <head>
        <style>
            body {{ font-family: sans-serif; text-align: center; padding: 50px; }}
            .header {{ background-color: #2ecc71; color: white; padding: 20px; border-radius: 10px; }}
            .info {{ color: #7f8c8d; margin-bottom: 30px; }}
            form {{ margin: 20px 0; }}
            input {{ padding: 10px; width: 250px; }}
            button {{ padding: 10px 20px; background: #27ae60; color: white; border: none; cursor: pointer; }}
            ul {{ list-style: none; padding: 0; }}
            li {{ background: #f4f4f4; margin: 5px; padding: 10px; border-radius: 5px; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Üdv a DevOps Appon!</h1>
            <h2>🚀 GREEN VERZIÓ 🚀</h2>
        </div>
        <p class="info">Szerver IP: {local_ip} | Host: {hostname}</p>
        
        <form action="/add" method="post">
            <input type="text" name="msg" placeholder="Üzenet az adatbázisba..." required>
            <button type="submit">Küldés</button>
        </form>

        <h3>Üzenetek az RDS-ből:</h3>
        <ul>
            {"".join([f"<li>{m[0]}</li>" for m in messages])}
        </ul>
    </body>
    </html>
    """

@app.route('/add', methods=['POST'])
def add():
    msg = request.form.get('msg')
    if msg:
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute('INSERT INTO messages (content) VALUES (%s)', (msg,))
            conn.commit()
            cursor.close()
            conn.close()
        except Exception as e:
            return f"Mentési hiba: {e}"
    return 'Üzenet mentve! <a href="/">Vissza</a>'

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=80)