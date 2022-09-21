#!/usr/bin/python3
import psycopg2
from decouple import config

DATABASE_HOST = config('DATABASE_HOST')
DATABASE_PORT = config('DATABASE_PORT')
DATABASE_USERNAME = config('DATABASE_USERNAME')
DATABASE_PASSWORD = config('DATABASE_PASSWORD')
DATABASE_NAME = config('DATABASE_NAME')

# Connect to the Database
conn = psycopg2.connect("host=%s port=%s dbname=%s user=%s password=%s" % (DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USERNAME, DATABASE_PASSWORD))
print(conn)

# Open a cursor to send SQL Commands
cur = conn.cursor()

# Select all invoices
sql = "SELECT * FROM invoice WHERE status='sent';"
cur.execute(sql)
invoices = cur.fetchall()

for invoice in invoices:
    reference = invoice[1]
    limit = invoice[13]
    print(reference)
    print(limit)
        
# Close connection
conn.close()
print(conn)
