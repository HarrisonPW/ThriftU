
-- drop DATABASE market;
--
--
-- CREATE DATABASE market;




CREATE TABLE "User" (
                        user_id SERIAL PRIMARY KEY,
                        email VARCHAR(255) NOT NULL UNIQUE,
                        username VARCHAR(255),
                        password VARCHAR(255) NOT NULL,
                        code VARCHAR(50),
                        active VARCHAR(50) DEFAULT '0',
                        create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE (username)
);

CREATE TABLE "Post" (
                        post_id SERIAL PRIMARY KEY,
                        post_type VARCHAR(255) ,
                        price NUMERIC(10, 2),
                        title TEXT,
                        description TEXT,
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

CREATE TABLE "Follow" (
                          follow_id SERIAL PRIMARY KEY,
                          follower_id INT NOT NULL,
                          following_id INT NOT NULL,
                          follow_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          UNIQUE (follower_id, following_id),
                          FOREIGN KEY (follower_id) REFERENCES "User"(user_id),
                          FOREIGN KEY (following_id) REFERENCES "User"(user_id)
);

CREATE TABLE "User_file" (
                             user_id INT NOT NULL,
                             file_id INT NOT NULL,
                             FOREIGN KEY (user_id) REFERENCES "User"(user_id),
                             FOREIGN KEY (file_id) REFERENCES "File"(file_id),
                             PRIMARY KEY (user_id, file_id)
);

