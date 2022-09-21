#!/usr/bin/python3
###############################################
## Librairies import
###############################################
import psycopg2
from decouple import config
from datetime import date

###############################################
## Getting environment variables
###############################################
DATABASE_HOST = config('DATABASE_HOST')
DATABASE_PORT = config('DATABASE_PORT')
DATABASE_USERNAME = config('DATABASE_USERNAME')
DATABASE_PASSWORD = config('DATABASE_PASSWORD')
DATABASE_NAME = config('DATABASE_NAME')

###############################################
## Configure DB
###############################################
conn = psycopg2.connect("host=%s port=%s dbname=%s user=%s password=%s" % (DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USERNAME, DATABASE_PASSWORD))
cur = conn.cursor()

###############################################
## Functions
###############################################
# Get formated date
def GetFormatedDate(date):
    date = date.split('/')
    return datetime.datetime(date[2], date[1], date[0])

# Update invoice
def UpdateInvoice(reference, limit):
    today = date.today()

    if today < limit:
        sql = ("UPDATE invoice SET status = 'overdue' WHERE reference = '%s';" % (reference))

# Select all invoices
def SelectInvoices():
    sql = "SELECT * FROM invoice WHERE status='sent';"
    cur.execute(sql)
    invoices = cur.fetchall()

    for invoice in invoices:
        UpdateInvoice(invoice[1], invoice[13])



###############################################
## Main
###############################################
SelectInvoices()

conn.close()


        
# Close connection

