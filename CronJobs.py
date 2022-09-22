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
# Update invoice
def UpdateDocument(table, status, reference, limit):
    today = date.today()

    if today > limit:
        sql = ("UPDATE %s SET status = '%s' WHERE reference = '%s';" % (table, status, reference))
        cur.execute(sql)

# Select all invoices
def SelectInvoices():
    sql = "SELECT * FROM invoice WHERE status='sent';"
    cur.execute(sql)
    invoices = cur.fetchall()

    for invoice in invoices:
        UpdateDocument("invoice", "overdue", invoice[1], invoice[13])

# Select all estimates
def SelectEstimates():
    sql = "SELECT * FROM estimate WHERE status='sent';"
    cur.execute(sql)
    estimates = cur.fetchall()

    for estimate in estimates:
        UpdateDocument("estimate", "late", estimate[1], estimate[13])


###############################################
## Main
###############################################
SelectInvoices()
SelectEstimates()
conn.close()
