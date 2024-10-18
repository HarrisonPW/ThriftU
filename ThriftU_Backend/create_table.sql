
drop DATABASE market;


CREATE DATABASE market;




CREATE TABLE "User" (
                        user_id SERIAL PRIMARY KEY,
                        email VARCHAR(255) NOT NULL UNIQUE,
                        password VARCHAR(255) NOT NULL,
                        code VARCHAR(50),
                        active VARCHAR(50) DEFAULT '0',
                        create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "Post" (
                        post_id SERIAL PRIMARY KEY,
                        post_type VARCHAR(10) ,
                        price NUMERIC(10, 2),
                        text TEXT,
                        create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        user_id INT NOT NULL);

CREATE TABLE "Reply" (
                         reply_id SERIAL PRIMARY KEY,
                         reply_by_user_id INT NOT NULL,
                         reply_text TEXT,
                         create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         to_user_id INT,
                         to_post_id INT,
                         to_reply_id INT
);

CREATE TABLE "Like" (
                        like_id SERIAL PRIMARY KEY,
                        reply_by_user_id INT NOT NULL,
                        post_id INT NOT NULL,
                        create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "File" (
                        file_id SERIAL PRIMARY KEY,
                        file_path VARCHAR(255) NOT NULL,
                        create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE "Post_file" (
                             file_id INT NOT NULL,
                             post_id INT NOT NULL
);



CREATE TABLE "Msg" (
                       msg_id SERIAL PRIMARY KEY,
                       to_user_id INT NOT NULL,
                       from_user_id INT NOT NULL,
                       create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                       text VARCHAR(255) ,
                       post_id INT
);
