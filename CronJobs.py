#!/usr/bin/python3
###############################################
## Librairies import
###############################################
import psycopg2
import requests
from decouple import config
from datetime import date, datetime, timedelta

###############################################
## Getting environment variables
###############################################
DATABASE_HOST = config('DATABASE_HOST')
DATABASE_PORT = config('DATABASE_PORT')
DATABASE_USERNAME = config('DATABASE_USERNAME')
DATABASE_PASSWORD = config('DATABASE_PASSWORD')
DATABASE_NAME = config('DATABASE_NAME')
USERNAME = config('ADMINISTRATOR_EMAIL')
PASSWORD = config('ADMINISTRATOR_PASSWORD')

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
def SelectInvoices(header):
    sql = "SELECT * FROM invoice WHERE (status='sent' OR status='overdue');"
    cur.execute(sql)
    invoices = cur.fetchall()

    for invoice in invoices:
        today = date.today()
        limitDate = invoice[11]
        invoiceId = invoice[0]
        sevenDay = limitDate - timedelta(days=7)

        if today == limitDate:
            response = requests.patch(("http://gestion.desyntic.com:2574/invoice/last/%s" % (invoiceId)), headers=header)
        elif today == sevenDay:
            response = requests.patch(("http://gestion.desyntic.com:2574/invoice/remainder/%s" % (invoiceId)), headers=header)
        elif today > limitDate:
            response = requests.patch(("http://gestion.desyntic.com:2574/invoice/delays/%s" % (invoiceId)), headers=header)

# Select all estimates
def SelectEstimates(header):
    sql = "SELECT * FROM estimate WHERE status='sent';"
    cur.execute(sql)
    estimates = cur.fetchall()

    for estimate in estimates:
        UpdateDocument("estimate", "late", estimate[1], estimate[13])


###############################################
## Main
###############################################
token = requests.post("http://gestion.desyntic.com:2574/staff/login", auth=(USERNAME, PASSWORD), json={"token": None}).json()["token"]
header = {'Authorization': 'Bearer ' + token}
SelectInvoices(header)
SelectEstimates(header)
conn.commit()
conn.close()
