from flask import Flask, request, jsonify, send_file
import psycopg2
from psycopg2 import sql
import random
import re  # Added import of the regular expression module
from EmailSender import send_verification_email
import jwt
import datetime
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Database connection information
# DB_HOST = "localhost"
# DB_NAME = "market"
# DB_USER = "postgres"
# DB_PASS = "mysecretpassword"

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_NAME = os.environ.get("DB_NAME", "market")
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASS = os.environ.get("DB_PASS", "mysecretpassword")

# Configure the file upload storage path
UPLOAD_FOLDER = 'uploads/'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


@app.before_request
def check_token():
    # If the request path is register, login, or activate, do not intercept
    if request.endpoint in ['register', 'login', 'activate_user', 'upload_file', 'get_file']:
        return

    # All other paths require token validation
    token = request.headers.get('Authorization')

    if not token:
        return jsonify({'error': 'Token is missing'}), 403

    # Validate the token
    result = verify_token(token)

    if 'error' in result:
        return jsonify(result), 403

    # If token validation is successful, continue processing the request
    # You can store `user_id` and `email` here and use them in subsequent requests
    request.user_id = result['user_id']
    request.email = result['email']


# Generate a 5-digit random verification code
def generate_code():
    return random.randint(10000, 99999)


# Function to validate email format
def is_valid_email(email):
    # Use a regular expression to check if the email format is valid
    email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    return re.match(email_regex, email) is not None


@app.route('/', methods=['GET'])
def home():
    return jsonify({'message': 'Welcome to our API'})


# Registration API
@app.route('/register', methods=['POST'])
def register():
    # Get data from the request
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    # Check if required fields are provided
    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    # Check if the email format is valid
    if not is_valid_email(email):
        return jsonify({'error': 'Invalid email format'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Check if the email already exists
        cursor.execute("SELECT * FROM \"User\" WHERE email = %s", (email,))
        existing_user = cursor.fetchone()

        if existing_user:
            return jsonify({'error': 'Email already exists'}), 400

        # Generate a random verification code
        code = generate_code()

        # Send verification email
        send_verification_email(email, code)

        insert_query = sql.SQL("INSERT INTO \"User\" (email, password, code) VALUES (%s, %s, %s)")
        cursor.execute(insert_query, (email, password, code))

        # Commit the changes and close the connection
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'User registered successfully'}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Activate user API
@app.route('/activate', methods=['POST'])
def activate_user():
    data = request.get_json()
    email = data.get('email')
    code = data.get('code')

    # Check if email and verification code are provided
    if not email or not code:
        return jsonify({'error': 'Email and verification code are required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Check if the user exists and if the verification code matches
        cursor.execute("SELECT code, active FROM \"User\" WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Check if the user is already activated
        if user[1] == 1:
            return jsonify({'error': 'User is already activated'}), 400

        # Check if the verification code matches
        if str(user[0]) != str(code):
            return jsonify({'error': 'Invalid verification code'}), 400

        # If validation is successful, update the user's status to activated (active = 1)
        cursor.execute("UPDATE \"User\" SET active = %s WHERE email = %s", (1, email))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'User activated successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Secret key used to sign and verify JWT
SECRET_KEY = 'secret_key'


# Validate and decode the token
def verify_token(token):
    try:
        decoded_token = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        user_id = decoded_token['user_id']
        email = decoded_token['email']
        return {'user_id': user_id, 'email': email}
    except jwt.ExpiredSignatureError:
        return {'error': 'Token has expired'}
    except jwt.InvalidTokenError:
        return {'error': 'Invalid token'}


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    # Check if email and password are provided
    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Query user information
        cursor.execute("SELECT user_id, password, active FROM \"User\" WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Check if the password is correct
        if user[1] != password:
            return jsonify({'error': 'Invalid password'}), 400

        # Check if the user is activated
        if user[2] != '1':
            return jsonify({'error': 'User not activated'}), 403

        # Generate JWT token
        token = jwt.encode({
            'user_id': user[0],
            'email': email,
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=12)  # Token expires in 12 hours
        }, SECRET_KEY, algorithm='HS256')

        cursor.close()
        conn.close()

        return jsonify({'message': 'Login successful', 'token': token}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Ensure the upload directory exists
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

import uuid


def generate_id():
    # Use uuid4 to generate a random unique identifier
    return str(uuid.uuid4())


# Upload file API
@app.route('/upload', methods=['POST'])
def upload_file():
    # Check if the request contains a file
    if 'file' not in request.files:
        return jsonify({'error': 'No file part in the request'}), 400

    file = request.files['file']

    # Check if the file has a name
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    if file:
        # Determine the file save path
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)

        # Save the file to the server
        file.save(file_path)

        # Store the file path in the database
        try:
            # Create a database connection
            conn = psycopg2.connect(
                host=DB_HOST,
                dbname=DB_NAME,
                user=DB_USER,
                password=DB_PASS
            )
            cursor = conn.cursor()

            # Insert file information into the file table
            insert_query = sql.SQL("INSERT INTO \"File\" ( file_path, create_time) VALUES (%s, %s) RETURNING file_id ")
            cursor.execute(insert_query, (file_path, datetime.datetime.utcnow()))
            file_id = cursor.fetchone()[0]
            # Commit the transaction and close the connection
            conn.commit()
            cursor.close()
            conn.close()

            print(file_id)

            return jsonify({'message': 'File uploaded successfully', 'file_id': file_id, 'file_path': file_path}), 201

        except Exception as e:
            return jsonify({'error': str(e)}), 500


# Create Post API
@app.route('/post', methods=['POST'])
def create_post():
    user_id = request.user_id

    # Get data from the request body
    data = request.get_json()
    post_type = data.get('post_type')
    price = data.get('price')
    title = data.get('title')
    description = data.get('description')
    file_ids = data.get('file_ids')  # Assuming file_ids is a list of file IDs

    if not post_type or not title or not description:
        return jsonify({'error': 'Post type, title, and description are required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Insert new post data
        insert_post_query = sql.SQL(
            "INSERT INTO \"Post\" (post_type, price, title,description, user_id, create_time) VALUES (%s, %s, %s, %s,%s, %s) RETURNING post_id"
        )
        cursor.execute(insert_post_query, (post_type, price, title, description, user_id, datetime.datetime.utcnow()))

        # Get the newly inserted post_id
        post_id = cursor.fetchone()[0]

        # Handle associated file_ids
        if file_ids:
            insert_post_file_query = sql.SQL("INSERT INTO \"Post_file\" (file_id, post_id) VALUES (%s, %s)")
            for file_id in file_ids:
                cursor.execute(insert_post_file_query, (file_id, post_id))

        # Commit the transaction and close the connection
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'Post created successfully', 'post_id': post_id}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Update Post API
@app.route('/post/update', methods=['POST'])
def update_post():
    user_id = request.user_id

    # Get data from the request body
    data = request.get_json()
    post_id = data.get('post_id')
    post_type = data.get('post_type')
    price = data.get('price')
    title = data.get('title')
    description = data.get('description')
    file_ids = data.get('file_ids')  # Assuming file_ids is a list of file IDs

    if not post_id or not post_type or not title or not description:
        return jsonify({'error': 'Post ID, post type, description, and title are required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Check if the post_id belongs to this user
        cursor.execute("SELECT user_id FROM \"Post\" WHERE post_id = %s", (post_id,))
        result = cursor.fetchone()
        if not result:
            return jsonify({'error': 'Post not found'}), 404

        if result[0] != user_id:
            return jsonify({'error': 'You are not allowed to edit this post'}), 403

        # Delete old associated data (files in Post_file table)
        cursor.execute("DELETE FROM \"Post_file\" WHERE post_id = %s", (post_id,))

        # Delete old post data
        cursor.execute("DELETE FROM \"Post\" WHERE post_id = %s", (post_id,))

        # Insert new post data
        insert_post_query = sql.SQL(
            "INSERT INTO \"Post\" (post_id, post_type, price, title, description, user_id, create_time) VALUES (%s, %s, %s, %s, %s, %s, %s)"
        )
        cursor.execute(insert_post_query,
                       (post_id, post_type, price, title, description, user_id, datetime.datetime.utcnow()))

        # Insert latest files associated with Post_file table
        if file_ids:
            insert_post_file_query = sql.SQL("INSERT INTO \"Post_file\" (file_id, post_id) VALUES (%s, %s)")
            for file_id in file_ids:
                cursor.execute(insert_post_file_query, (file_id, post_id))

        # Commit the transaction and close the connection
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'Post updated successfully', 'post_id': post_id}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Retrieve image/video API
@app.route('/file/<int:file_id>', methods=['GET'])
def get_file(file_id):
    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Query the file path based on file_id
        cursor.execute("SELECT file_path FROM \"File\" WHERE file_id = %s", (file_id,))
        file_data = cursor.fetchone()

        if not file_data:
            return jsonify({'error': 'File not found'}), 404

        file_path = file_data[0]

        # Close the database connection
        cursor.close()
        conn.close()

        # Check if the file exists
        if not os.path.exists(file_path):
            return jsonify({'error': 'File does not exist on server'}), 404

        # Return the file content to the frontend, suitable for binary files like images or videos
        return send_file(file_path, as_attachment=False)

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Retrieve user posts API
@app.route('/posts', methods=['GET'])
def get_user_posts():
    user_id = request.user_id

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Query all posts and associated file information for the user
        query = """
        SELECT p.post_id, p.post_type, p.price, p.title, p.description, p.create_time, f.file_id
        FROM "Post" p
        LEFT JOIN "Post_file" pf ON p.post_id = pf.post_id
        LEFT JOIN "File" f ON pf.file_id = f.file_id
        WHERE p.user_id = %s
        """
        cursor.execute(query, (user_id,))
        posts = cursor.fetchall()

        # If no posts are found
        if not posts:
            return jsonify({'message': 'No posts found for this user'}), 200

        # Construct the list of posts and associated files
        posts_data = {}
        for post in posts:
            post_id = post[0]
            if post_id not in posts_data:
                posts_data[post_id] = {
                    'post_id': post[0],
                    'post_type': post[1],
                    'price': float(post[2]),
                    'title': post[3],
                    'description': post[4],
                    'create_time': post[5].strftime('%Y-%m-%d %H:%M:%S'),
                    'files': []
                }
            # Add file path to the list of files for this post
            if post[5]:
                posts_data[post_id]['files'].append(post[5])

        # Convert the dictionary to a list
        posts_list = list(posts_data.values())

        # Close the database connection
        cursor.close()
        conn.close()

        return jsonify({'posts': posts_list}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Like or unlike a post API
@app.route('/like', methods=['POST'])
def like_post():
    user_id = request.user_id

    # Get post_id from the request body
    data = request.get_json()
    post_id = data.get('post_id')

    if not post_id:
        return jsonify({'error': 'Post ID is required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Check if the post exists
        cursor.execute("SELECT post_id FROM \"Post\" WHERE post_id = %s", (post_id,))
        post = cursor.fetchone()

        if not post:
            return jsonify({'error': 'Post not found'}), 404

        # Check if the user has already liked the post
        cursor.execute("SELECT like_id FROM \"Like\" WHERE reply_by_user_id = %s AND post_id = %s", (user_id, post_id))
        like = cursor.fetchone()

        if like:
            # If the user already liked the post, remove the like (delete the record)
            cursor.execute("DELETE FROM \"Like\" WHERE like_id = %s", (like[0],))
            message = 'Post unliked successfully'
        else:
            # If the user hasn't liked the post, insert a new like record
            insert_like_query = sql.SQL(
                "INSERT INTO \"Like\" (reply_by_user_id, post_id, create_time) VALUES (%s, %s, %s)"
            )
            cursor.execute(insert_like_query, (user_id, post_id, datetime.datetime.utcnow()))
            message = 'Post liked successfully'

        # Commit the transaction and close the connection
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': message}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Retrieve the number of likes for a post
@app.route('/post/<int:post_id>/likes', methods=['GET'])
def get_post_likes(post_id):
    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Check if the post exists
        cursor.execute("SELECT post_id FROM \"Post\" WHERE post_id = %s", (post_id,))
        post = cursor.fetchone()

        if not post:
            return jsonify({'error': 'Post not found'}), 404

        # Query the number of likes for the post
        cursor.execute("SELECT COUNT(*) FROM \"Like\" WHERE post_id = %s", (post_id,))
        like_count = cursor.fetchone()[0]

        # Close the database connection
        cursor.close()
        conn.close()

        return jsonify({'post_id': post_id, 'like_count': like_count}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Reply to post API
@app.route('/reply', methods=['POST'])
def reply_post():
    user_id = request.user_id

    # Get data from the request body
    data = request.get_json()
    post_id = data.get('to_post_id')  # ID of the post being commented on
    reply_id = data.get('to_reply_id')  # ID of the comment being replied to, optional
    reply_text = data.get('reply_text')

    if not reply_text or (not post_id and not reply_id):
        return jsonify({'error': 'Reply text and either post_id or reply_id are required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # If replying to a post, check if the post exists
        if post_id:
            cursor.execute("SELECT post_id, user_id FROM \"Post\" WHERE post_id = %s", (post_id,))
            post = cursor.fetchone()
            if not post:
                return jsonify({'error': 'Post not found'}), 404
            to_user_id = post[1]  # The target user is the author of the post

        # If replying to a comment, check if the comment exists
        if reply_id:
            cursor.execute("SELECT reply_id, reply_by_user_id FROM \"Reply\" WHERE reply_id = %s", (reply_id,))
            reply = cursor.fetchone()
            if not reply:
                return jsonify({'error': 'Reply not found'}), 404
            to_user_id = reply[1]  # The target user is the author of the original reply

        # Insert the reply or comment record
        insert_reply_query = sql.SQL(
            "INSERT INTO \"Reply\" (reply_by_user_id, reply_text, create_time, to_user_id, to_post_id, to_reply_id) VALUES (%s, %s, %s, %s, %s, %s)"
        )
        cursor.execute(insert_reply_query,
                       (user_id, reply_text, datetime.datetime.utcnow(), to_user_id, post_id, reply_id))

        # Commit the transaction and close the connection
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'Reply posted successfully'}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Retrieve all replies to a post API
@app.route('/post/<int:post_id>/replies', methods=['GET'])
def get_post_replies(post_id):
    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Check if the post exists
        cursor.execute("SELECT post_id FROM \"Post\" WHERE post_id = %s", (post_id,))
        post = cursor.fetchone()

        if not post:
            return jsonify({'error': 'Post not found'}), 404

        # Query all replies to the post, including the email of the commenter, reply text, and creation time
        query = """
        SELECT u.email, r.reply_text, r.create_time 
        FROM "Reply" r
        JOIN "User" u ON r.reply_by_user_id = u.user_id
        WHERE r.to_post_id = %s 
        ORDER BY r.create_time ASC
        """
        cursor.execute(query, (post_id,))
        replies = cursor.fetchall()

        # If no replies are found
        if not replies:
            return jsonify({'message': 'No replies found for this post'}), 200

        # Construct the reply list
        replies_data = []
        for reply in replies:
            replies_data.append({
                'email': reply[0],
                'reply_text': reply[1],
                'create_time': reply[2].strftime('%Y-%m-%d %H:%M:%S')  # Format the time
            })

        # Close the connection
        cursor.close()
        conn.close()

        return jsonify({'replies': replies_data}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Delete post API
@app.route('/post/delete', methods=['POST'])
def delete_post():
    user_id = request.user_id

    # Get post_id from the request body
    data = request.get_json()
    post_id = data.get('post_id')

    if not post_id:
        return jsonify({'error': 'Post ID is required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Check if the post exists and belongs to the current user
        cursor.execute("SELECT user_id FROM \"Post\" WHERE post_id = %s", (post_id,))
        post = cursor.fetchone()

        if not post:
            return jsonify({'error': 'Post not found'}), 404

        if post[0] != user_id:
            return jsonify({'error': 'You are not allowed to delete this post'}), 403

        # Delete all comments related to this post
        cursor.execute("DELETE FROM \"Reply\" WHERE to_post_id = %s", (post_id,))

        # Delete all file associations related to this post
        cursor.execute("DELETE FROM \"Post_file\" WHERE post_id = %s", (post_id,))

        # Delete the post itself
        cursor.execute("DELETE FROM \"Post\" WHERE post_id = %s", (post_id,))

        # Commit the changes and close the connection
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'Post and associated data deleted successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Delete reply API
@app.route('/reply/delete', methods=['POST'])
def delete_reply():
    user_id = request.user_id

    # Get reply_id from the request body
    data = request.get_json()
    reply_id = data.get('reply_id')

    if not reply_id:
        return jsonify({'error': 'Reply ID is required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Check if the reply exists and belongs to the current user
        cursor.execute("SELECT reply_by_user_id FROM \"Reply\" WHERE reply_id = %s", (reply_id,))
        reply = cursor.fetchone()

        if not reply:
            return jsonify({'error': 'Reply not found'}), 404

        if reply[0] != user_id:
            return jsonify({'error': 'You are not allowed to delete this reply'}), 403

        # Delete the reply
        cursor.execute("DELETE FROM \"Reply\" WHERE reply_id = %s", (reply_id,))

        # Commit the transaction and close the connection
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'Reply deleted successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Send message API (chat functionality)
@app.route('/chat/send', methods=['POST'])
def send_message():
    from_user_id = request.user_id

    # Get data from the request body
    data = request.get_json()
    to_user_id = data.get('to_user_id')
    post_id = data.get('post_id')
    text = data.get('text')

    if not to_user_id or not post_id or not text:
        return jsonify({'error': 'To_user_id, post_id, and text are required'}), 400

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Insert chat message record
        insert_msg_query = sql.SQL(
            "INSERT INTO \"Msg\" (to_user_id, from_user_id, create_time, text, post_id) VALUES (%s, %s, %s, %s, %s)"
        )
        cursor.execute(insert_msg_query, (to_user_id, from_user_id, datetime.datetime.utcnow(), text, post_id))

        # Commit the transaction and close the connection
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'Message sent successfully'}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Retrieve user messages (chat functionality)
@app.route('/chat/messages', methods=['GET'])
def get_user_messages():
    user_id = request.user_id

    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        # Query all chat messages related to the user as either the sender or receiver
        query = """
        SELECT msg_id, to_user_id, from_user_id, create_time, text, post_id
        FROM "Msg"
        WHERE to_user_id = %s OR from_user_id = %s
        ORDER BY create_time DESC
        """
        cursor.execute(query, (user_id, user_id))
        messages = cursor.fetchall()

        # If no messages are found
        if not messages:
            return jsonify({'message': 'No messages found'}), 200

        # Construct the message list with user and post details
        messages_data = []
        for msg in messages:
            # Fetch the sender and recipient details (optional, could be optimized to avoid multiple queries)
            cursor.execute("SELECT email FROM \"User\" WHERE user_id = %s", (msg[1],))
            to_user = cursor.fetchone()
            cursor.execute("SELECT email FROM \"User\" WHERE user_id = %s", (msg[2],))
            from_user = cursor.fetchone()

            messages_data.append({
                'msg_id': msg[0],
                'to_user_email': to_user[0] if to_user else 'Unknown',
                'from_user_email': from_user[0] if from_user else 'Unknown',
                'create_time': msg[3].strftime('%Y-%m-%d %H:%M:%S'),
                'text': msg[4],
                'post_id': msg[5]
            })

        # Close the database connection
        cursor.close()
        conn.close()

        return jsonify({'messages': messages_data}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/follow', methods=['POST'])
def follow_user():
    user_id = request.user_id  # Get the current user's ID from the token
    data = request.get_json()
    following_id = data.get('following_id')

    if not following_id:
        return jsonify({'error': 'Following user ID is required'}), 400

    try:
        conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASS)
        cursor = conn.cursor()

        # Insert follow record if it doesn't already exist
        insert_query = sql.SQL(
            "INSERT INTO \"Follow\" (follower_id, following_id) VALUES (%s, %s) ON CONFLICT DO NOTHING"
        )
        cursor.execute(insert_query, (user_id, following_id))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'User followed successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/unfollow', methods=['POST'])
def unfollow_user():
    user_id = request.user_id
    data = request.get_json()
    following_id = data.get('following_id')

    if not following_id:
        return jsonify({'error': 'Following user ID is required'}), 400

    try:
        conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASS)
        cursor = conn.cursor()

        # Delete the follow record
        delete_query = sql.SQL("DELETE FROM \"Follow\" WHERE follower_id = %s AND following_id = %s")
        cursor.execute(delete_query, (user_id, following_id))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'User unfollowed successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/followers/<int:user_id>', methods=['GET'])
def get_followers(user_id):
    try:
        conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASS)
        cursor = conn.cursor()

        # Query followers for the given user
        query = """
        SELECT u.user_id, u.email
        FROM "Follow" f
        JOIN "User" u ON f.follower_id = u.user_id
        WHERE f.following_id = %s
        """
        cursor.execute(query, (user_id,))
        followers = cursor.fetchall()

        followers_list = [{'user_id': follower[0], 'email': follower[1]} for follower in followers]

        cursor.close()
        conn.close()

        return jsonify({'followers': followers_list}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/following/<int:user_id>', methods=['GET'])
def get_following(user_id):
    try:
        conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASS)
        cursor = conn.cursor()

        # Query users that the given user is following
        query = """
        SELECT u.user_id, u.email
        FROM "Follow" f
        JOIN "User" u ON f.following_id = u.user_id
        WHERE f.follower_id = %s
        """
        cursor.execute(query, (user_id,))
        following = cursor.fetchall()

        following_list = [{'user_id': follow[0], 'email': follow[1]} for follow in following]

        cursor.close()
        conn.close()

        return jsonify({'following': following_list}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Search by email
@app.route('/search_user', methods=['GET'])
def search_user():
    email = request.args.get('email')  # Example: search_user?email=xxxx@gmail.com

    if not email:
        return jsonify({'error': 'Email is required'}), 400

    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()
        cursor.execute("SELECT user_id, active FROM \"User\" WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({'error': 'User not found'}), 404

        user_id, active = user

        if active != '1':
            return jsonify({'error': 'User is not activated'}), 403

        cursor.close()
        conn.close()

        return jsonify({'user_id': user_id}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/post/<int:post_id>', methods=['GET'])
def get_post_by_id(post_id):
    try:
        # Create a database connection
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()
        query = """
        SELECT p.post_id, p.post_type, p.price, p.title, p.description, p.create_time, u.email
        FROM "Post" p
        JOIN "User" u ON p.user_id = u.user_id
        WHERE p.post_id = %s
        """
        cursor.execute(query, (post_id,))
        post = cursor.fetchone()

        if not post:
            return jsonify({'error': 'Post not found'}), 404

        cursor.execute(
            "SELECT f.file_id, f.file_path FROM \"Post_file\" pf JOIN \"File\" f ON pf.file_id = f.file_id WHERE pf.post_id = %s",
            (post_id,))
        files = cursor.fetchall()

        files_list = [{'file_id': file[0], 'file_path': file[1]} for file in files]

        post_data = {
            'post_id': post[0],
            'post_type': post[1],
            'price': float(post[2]) if post[2] else None,
            'title': post[3],
            'description': post[4],
            'create_time': post[5].strftime('%Y-%m-%d %H:%M:%S'),
            'user_email': post[6],
            'files': files_list
        }

        cursor.close()
        conn.close()

        return jsonify({'post': post_data}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/all_posts', methods=['GET'])
def get_all_posts():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()
        query = """
        SELECT p.post_id, p.post_type, p.price, p.title, p.description, p.create_time, u.email
        FROM "Post" p
        JOIN "User" u ON p.user_id = u.user_id
        LEFT JOIN "Post_file" pf ON p.post_id = pf.post_id
        LEFT JOIN "File" f ON pf.file_id = f.file_id
        """
        cursor.execute(query)
        posts = cursor.fetchall()
        posts_data = {}
        for post in posts:
            post_id = post[0]
            if post_id not in posts_data:
                posts_data[post_id] = {
                    'post_id': post[0],
                    'post_type': post[1],
                    'price': float(post[2]) if post[2] else None,
                    'title': post[3],
                    'description': post[4],
                    'create_time': post[5].strftime('%Y-%m-%d %H:%M:%S'),
                    'user_email': post[6],
                    'files': []
                }
            if post[7]:
                posts_data[post_id]['files'].append(post[7])

        posts_list = list(posts_data.values())
        cursor.close()
        conn.close()

        return jsonify({'posts': posts_list}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/chat2/send', methods=['POST'])
def send_message_without_post():
    from_user_id = request.user_id
    data = request.get_json()
    to_user_id = data.get('to_user_id')
    text = data.get('text')

    if not to_user_id or not text:
        return jsonify({'error': 'To_user_id and text are required'}), 400

    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        insert_msg_query = sql.SQL(
            "INSERT INTO \"Msg\" (to_user_id, from_user_id, create_time, text) VALUES (%s, %s, %s, %s)"
        )
        cursor.execute(insert_msg_query, (to_user_id, from_user_id, datetime.datetime.utcnow(), text))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'message': 'Message sent successfully'}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/chat2/messages', methods=['GET'])
def get_user_messages_without_post():
    user_id = request.user_id

    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cursor = conn.cursor()

        query = """
        SELECT msg_id, to_user_id, from_user_id, create_time, text
        FROM "Msg"
        WHERE to_user_id = %s OR from_user_id = %s
        ORDER BY create_time DESC
        """
        cursor.execute(query, (user_id, user_id))
        messages = cursor.fetchall()

        if not messages:
            return jsonify({'message': 'No messages found'}), 200

        messages_data = []
        for msg in messages:
            cursor.execute("SELECT email FROM \"User\" WHERE user_id = %s", (msg[1],))
            to_user = cursor.fetchone()
            cursor.execute("SELECT email FROM \"User\" WHERE user_id = %s", (msg[2],))
            from_user = cursor.fetchone()

            messages_data.append({
                'msg_id': msg[0],
                'to_user_email': to_user[0] if to_user else 'Unknown',
                'from_user_email': from_user[0] if from_user else 'Unknown',
                'create_time': msg[3].strftime('%Y-%m-%d %H:%M:%S'),
                'text': msg[4]
            })

        cursor.close()
        conn.close()

        return jsonify({'messages': messages_data}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
