import sys
from tkinter import *
from tkinter import ttk

class LoginWin:

  #########################
  def __init__(self, parent):
    self.dlg = Toplevel(parent)
    self.dlg.title("CyberArk User Login")
    self.dlg.protocol("WM_DELETE_WINDOW", self.dismiss)

    loginFrame = ttk.LabelFrame(self.dlg, padding="3 3 12 12")
    loginFrame.grid(column=0, row=0, sticky=(N, W, E, S))
    loginFrame.columnconfigure(0, weight=1)
    loginFrame.rowconfigure(0, weight=1)

    ttk.Label(loginFrame, text="User Name").grid(column=0, row=1, sticky=W)
    self.login = StringVar()
    self.login_entry = ttk.Entry(loginFrame, width=15, textvariable=self.login)
    self.login_entry.grid(column=2, row=1, sticky=(W, E))

    ttk.Label(loginFrame, text="Password").grid(column=0, row=2, sticky=W)
    self.password= StringVar()
    password_entry = ttk.Entry(loginFrame, show="*", width=15, textvariable=self.password)
    password_entry.grid(column=2, row=2, sticky=(W, E))

    ttk.Button(self.dlg, text="Login", command=self.authenticate).grid()
    self.dlg.bind("<Return>", self.authenticate)
    self.dlg.transient(parent)
    self.dlg.wait_visibility()
    self.dlg.grab_set()
    self.dlg.wait_window()

  #########################
  def authenticate(self, *args):

      # authentication code goes here

      self.dlg.grab_release()
      self.dlg.destroy()

  #########################
  def dismiss (self, *args):
      self.dlg.grab_release()
      self.dlg.destroy()
      raise SystemExit
