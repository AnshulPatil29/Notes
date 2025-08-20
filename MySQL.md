# MySQL

*These are notes I created when reading Paul DuBois's MySQL Fifth Edition. The notes follow chapter numbering scheme*

## 1. Getting Started with MySQL

### 1.1 How SQL can help you

#### What it helps in:

- Reduced record filling time

- Reduced record retrieval time

- Flexible retrieval order

- Flexible output format

- Simultaneous multiple-user access to records

- Remote access to and electronic transmission of records

### 1.2 A Sample Database (Skipped)

### 1.3 Basic Database Terminology

#### 1.3.1 Structural Terminology

The **database** is a repository for the information you store, structure in a simple, regular fashion.

- The collection of data in a database is organized into **tables**.

- Each row in a table is a **record**.

- Records can contain several pieces of information; each **column** in a table corresponds to one of those pieces. 

The **management system** is the software that lets you use your data by enabling you to insert, retrieve, modify or delete records.

The **relational** in RDBMS indicated a type of DBMS which is particularly good at relating information stored in one table to information stored in other by joining related information to answer questions that cant be solved with information from one table alone.

#### 1.3.2 Query Language Terminology

Communication with DBMS takes place with **SQL**(Structured Query Language).

#### 1.3.3 MySQL Architectural Terminology

When using MySQL, we are using at least two programs, because MySQL operated on *client/server* architecture. One program is the MySQL server, `mysqld`. 

The server runs on the machine where your databased are stored. It listens for client requests coming on over the network and access database contents according to those requests to provide clients with the information they ask for.

The other programs are client programs; they connect to the database server and issue queries to tell it what information they want.

The most common client program is `mysql`, an interactive program that lets you issue queries and see the result.

Two administrative clients are `mysqldump`, a backup program that dumps table contents into a file, and `mysqladmin`, which enables you to check on the status of the server and perform other administrative tasks such as telling the server to shut down.

MySQL provides a client-programming library which lets you write your own programs if the standard clients are not suited for your requirement.

**Benefits of the client/server architecture**: (TLDR: separates control/management and accessing)

- The server enforces **concurrency control** to prevent two users from modifying the same record at the same time. All client requests go through the server, so the server sorts out who gets to do what, and when. 

- You need not be logged into the machine where your database is located. Since the database works in a networked environment, you can run the client program wherever you want, and access the database as long as you have access provided and access to the network.

### 1.4 A MySQL Tutorial

> Note: If the server is not running, run the service by running 
> 
> ```bash
> net start MySQL80
> ```

> This must be run in admin mode as services require admin privileges to run.

#### 1.4.5 Creating a Database

Using a database involves several steps:

- Creating the database

- Creating the tables within the database

- Manipulating the tables by inserting, retrieving, modifying, or deleting data

To create a new database user `CREATE DATABASE <database-name>`

```sql
CREATE DATABASE sampdb;
```

You might expect that creating a database would make it the default database, but you need to select it to use it. You can see this by running:

```sql
SELECT DATABASE();
```

Hence to select the database run:

```sql
USE sampdb;
```

Another way to use a database is to name it on the command line when you invoke mysql:

```bash
mysql sampdb
```

That is, in fact, the **usual way** to select the database you want to use. If you need any connection parameters, specify them on the command line. For example the following command enables the `sampadm` user to connect to the `sampdb` database on the local host:

```bash
mysql -p -u sampadm sampdb
```

#### 1.4.6 Creating Tables

The `president` table:

- **Name**: Names can be represented in a table several ways, such as a single column containing the entire name, or separate columns for the first and last name. It's simpler to use a single column but that limits your flexibility. To avoid these limitations, our `president` table  will use separate columns for the first and last name.
  
  This has a complication. Some names have 'Jr.' at the end, where will this go? This does not work as either First name or Last name, hence to fix this we need a suffix column. This shows that even a single record can cause problems.

- **Birthplace**: We will store this using *city* and *state* as with the name for the flexibility.

- **Birth date and death date**: The special problem here is we cannot require the death date column to be filled as some presidents are still living. Hence these will be filled with `NULL` , a special value indicating lack of any value.

The `member` table:

I am simply mentioning the fields as the above example shows the reasoning process aptly:

- **Name**: First name, Last name and suffix

- **ID number**: Unique identifier

- **Expiration Date**

- **Email Address**

- **Postal address**: Needed for contacting members without email. Columns:- street address, city, state, and ZIP code.

- **Phone number**

- **Special Interest Keywords**

##### 1.4.6.1 Creating the historical league tables:

To create a table, the statement has the general form of 

```sql
CREATE TABLE tbl_name (column_specs)
```

For the `president` table, write the `CREATE TABLE` statement as follows:

```sql
CREATE TABLE president 
(
    last_name VARCHAR(15) NOT NULL,
    first_name VARCHAR(15) NOT NULL,
    suffix VARCHAR(5) NULL,
    city VARCHAR(20) NOT NULL,
    state CHAR(2) NOT NULL,
    birth DATE NOT NULL,
    death DATE NULL
);
```

This can be executed in shell or saved to a file and run using 

```bash
mysql sampdb < create_president.sql
```

- Here `VARCHAR(max_size)` indicates that that column allows for variable length strings with maximum length of `max_size`.

- `NOT NULL` indicates that this value must exist and cannot be NULL. Since suffix may or may not exists(similarly death date), these must be NULLABLE.

- `suffix` is set to `CHAR(2)` as all states are represented by ***exactly 2***  characters.

- **IMPORTANT**: The `DATE` datatype follows the SQL standard date representation of `CCYY-MM-DD` (also knows as "ISO 8601 format") where `CC`, `YY` , `MM` and `DD` represent the century, year, month and day respectively.

For the `member` table, the `CREATE TABLE` statement looks like this:

```sql
CREATE TABLE member
(
    member_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    PRIMARY KEY(member_id),
    last_name VARCHAR(20) NOT NULL,
    first_name VARCHAR(20) NOT NULL,
    suffix VARCHAR(5) NULL,
    expiration DATE NULL,
    email VARCHAR(100) NULL,
    street VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    state CHAR(2) NULL,
    zip VARCHAR(10) NULL,
    phone VARCHAR(20) NULL,
    interests VARCHAR(255) NULL
);
```

Lets breakdown the `member_id` definition:

- `INT` signifies integer datatype

- `UNSIGNED` prohibits negative values

- `NOT NULL` makes this a required data field to create a row

- `AUTO_INCREMENT` is a special attribute in MySQL. It indicates that the column holds sequence numbers, The `AUTO_INCREMENT` mechanism works like this: If you provide no value for the `member_id` column when you create a new `member` table row, MySQL automatically generates the next sequence number and assigns it to the column. This special behavior also occurs if you assign it the value `NULL`.

- `PRIMARY KEY` indicates that this column is indexed to enable fast lookups. It also sets up the `NOT NULL` and `UNIQUE` constraint.

- Note: MySQL requires `AUTO_INCREMENT` to have some kind of index (no idea what it means but seemed important to note here so I can refer back later)  

Now that we have created a few tables, we can check out the structure of the tables by using:

```sql
DESCRIBE president
```

This will yield an output like:

```bash
+------------+-------------+------+-----+---------+-------+
| Field      | Type        | Null | Key | Default | Extra |
+------------+-------------+------+-----+---------+-------+
| last_name  | varchar(15) | NO   |     | NULL    |       |
| first_name | varchar(15) | NO   |     | NULL    |       |
| suffix     | varchar(5)  | YES  |     | NULL    |       |
| city       | varchar(20) | NO   |     | NULL    |       |
| state      | char(2)     | NO   |     | NULL    |       |
| birth      | date        | NO   |     | NULL    |       |
| death      | date        | YES  |     | NULL    |       |
+------------+-------------+------+-----+---------+-------+
7 rows in set (0.00 sec)
```

`NULL` in default indicates that the column has no explicitly defined default case.

This order is important when using `INSERT` or `LOAD DATA`.

> The following statements are synonymous:
> 
> ```sql
> DESCRIBE president;
> DESC president;
> EXPLAIN president;
> SHOW COLUMNS FROM president;
> SHOW FIELDS FROM president;
> ```

> These also allow you to restrict description to only certain columns by adding constraints. example:
> 
> ```sql
> SHOW COLUMNS FROM president LIKE "%name";
> ```

> `SHOW FULL COLUMNS` displays additional information.

The `SHOW` statement is also useful to show other information such as `TABLES` and `DATABASES`

Running `SHOW DATABASES` yields:

```bash
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mydb               |
| mysql              |
| performance_schema |
| sampdb             |
| sys                |
+--------------------+
6 rows in set (0.00 sec)
```

**IMPORTANT**: The database `information_schema` will always exists as it is a special database. It is a *virtual database* which holds metadata and can be queried. It contains metadata about the tables. (Think of it like a database of databases)

##### 1.4.6.2 Creating the Grade-Keeping tables:

Here the book talks about how certain column's value depends on another column's value (in the case of the books example on page 40, it shows how the category depends on the date of the examination)

This is used to present a use-case and advantage of using related and normalized tables. The book goes on to justify how creating two tables is not extra work as that work is already being done when we create the extra column in the original table.

This does impose a requirement that the linked column in this case `grade_event`, must be unique since when we link the two tables, a singular row cannot map to multiple entries. [`FOREIGN KEY` must exist and be unique in the table we are linking it to].

The problem in this case is that `grade_event` refers to what test happened on that day. But is it reasonable to assume that no more than one grade event will happen on a single day? Looking at the data, that may seem to be the case, but we can't be sure that such a case will never occur in future.

To fix this, the solution is rather simple: create a `grade_event_table` such that it has a unique ID for each event, and its corresponding date and category. The unique ID means that the uniqueness requirement is now fulfilled for that key, without forcing the dates to be unique.

This would give two tables (dummy data) with structure:

**`grade_event_table`**

```bash
+----------+------------+----------+
| event_id | date       | category |
+----------+------------+----------+
|        1 | 2024-08-01 | exam     |
|        2 | 2024-08-15 | quiz     |
|        3 | 2024-08-30 | project  |
+----------+------------+----------+
```

**`score_table`**

```bash
+-------+----------+-------+
| name  | event_id | score |
+-------+----------+-------+
| John  |        1 |    85 |
| Alice |        1 |    92 |
| John  |        2 |    78 |
| Alice |        2 |    88 |
| John  |        3 |    90 |
| Alice |        3 |    95 |
+-------+----------+-------+
```

> At this point the author addresses concerns about this abstraction not keeping the data human readable by clarifying that data being separated like this in RDBMS is not a problem as it can be JOINED to be human readable quite easily.

Another small change is that instead of using `name`, we will be using `student_id` in the `score_table` and then use a `student` table which stores the details of that student such as `name` `sex` and `student_id`. This is useful as we can store more information without duplicating it redundantly, and avoid the problem of students having the same name.

Here is an example query to retrieve the scores fora  given date:

```sql
SELECT student.name ,grade_event.date, score.score, grade_event.category
FROM grade_event INNER JOIN score INNER JOIN student
ON grade_event.event_id =score.event_id
AND score.student_id=student.student_id
WHERE grade_event.date = '2012-09-23';
```

**The `student` table**

```sql
CREATE TABLE student
(
  name VARCHAR(20) NOT NULL,
  sex ENUM('F','M') NOT NULL,
  student_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  PRIMARY KEY(student_id)  
)ENGINE=InnoDB;
```

- `ENUM({comma-separated-choices})`: this enforces a strict set of choices for the value of this column for any row. The choices must be of the same datatype, and internally, they are all coerced into strings.

- `ENGINE`: This clause, if present, names the storage engine that MySQL should use for creating the table. A "storage engine" is a handler that manages certain kind of table. At this stage this storage engine term is not explained; as far as I have understood,  the ENGINE decides how the data is stored, and certain engines may be better based on the requirements such as: transaction heavy, read heavy, temporary lookups etc.

- Here `InnoDB`, the default storage engine of SQL has been used due to a property called "referential integrity" (to create an entry, the corresponding key must exist in the table where the foreign key is a primary key).

**The `grade_event` table**

```sql
CREATE TABLE grade_event
(
    date DATE NOT NULL,
    category ENUM('T','Q') NOT NULL,
    event_id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    PRIMARY KEY(event_id)
)ENGINE=InnoDB;
```

**The `score` table**

```sql
CREATE TABLE score
(
    student_id INT UNSIGNED NOT NULL,
    event_id INT UNSIGNED NOT NULL,
    score INT NOT NULL,
    PRIMARY KEY(event_id,student_id),
    INDEX(student_id),
    FOREIGN KEY(event_id) REFERENCES grade_event(event_id),
    FOREIGN KEY(student_id) REFERENCES student(student_id),
)ENGINE=InnoDB;
```

> This is where we talk about composite keys and foreign keys.

- Here the primary key is comprised of two attributes, namely `student_id` and `event_id`, neither of which by themselves are unique but taken as a set, together they are unique. This prevents the score for any student for a particular test being duplicated.

- The `FOREIGN KEY` constraint forces the *referential integrity* that was mentioned earlier. Simply put, it means that for the constraint of structure: `FOREIGN KEY(column-name) REFERENCES table-name(corresponding-column-name)`, for any entry in this table, the corresponding value must exist in the `corresponding-column-name` of `table-name`. Lets take an example of `event_id`, this ensures that no score is added for an event which does not exist in the `grade_event` table first. Which makes logical sense as how can a score exist for a test which did not occur.

- **IMPORTANT**: Why is there an index on `student_id`? Before we answer that, what is an *index*?

> Indexing is a way to speed up data retrieval by minimizing disk scans. Instead of searching through all the rows, DBMS uses index structures which locate data using key values.
> 
> **Attributes of indexing**:
> 
> - Access types
> 
> - Access time
> 
> - Insertion time
> 
> - Deletion time
> 
> - Space overhead
> 
> Indexing seems like an entire topic by itself so I will look into it later. Right now, getting back to the question of why there is an index on `student_id`

The reason is that, for any columns in a `FOREIGN KEY` definition, there should be an index on them or they should be the columns that are listed first in a multiple-column index, to enable faster lookups. For the `FOREIGN KEY` on `event_id`, it is listed first in the `PRIMARY KEY` but `student_id` is not, hence we create a separate index for it.

InnoDB does create an index automatically if required, but it might not use the same index definition. Defining it explicitly avoids this issue. 
