import os
import sys
import time
import subprocess
from tkinter import *
from tkinter import ttk
from projectinfo import *
from identityinfo import *
from accountinfo import *

class AccessRequestDetails:

  def __init__(self, parent):
    mainframe = ttk.Frame(parent, padding="12 12 12 12")
    mainframe.grid(column=0, row=1, sticky=(N, W, E, S))

    projectFrame = ttk.Frame(mainframe, padding="10 10 10 10", style='Cybr.TFrame')
    projectFrame.grid(column=0, row=0, sticky=(N, W, E, S))
    self.projectInfo = ProjectInfo(projectFrame)

    identityFrame = ttk.Frame(mainframe, padding="10 10 10 10", style='Cybr.TFrame')
    identityFrame.grid(column=0, row=1, sticky=(N, W, E, S))
    self.identityInfo = IdentityInfo(identityFrame)

    accountFrame = ttk.Frame(mainframe, padding="10 10 10 10", style='Cybr.TFrame')
    accountFrame.grid(column=0, row=2, sticky=(N, W, E, S))
    self.accountInfo = AccountInfo(accountFrame)

    ttk.Button(parent, text="Submit", command=self.submit, style='Cybr.TButton').grid(column=3, row=3, sticky=E)
    parent.bind("<Return>", self.submit)

    self.projectInfo.project_entry.focus()

    for child in parent.winfo_children():
        child.grid_configure(padx=10, pady=10)

  ######################################
  def submit(self, *args):
    try:
      # temporarily redirect stdout to file
      stdout_old = sys.stdout
      sys.stdout = open("auto-acc-req.json", 'w')
      print("{")
      self.projectInfo.print()
      print(",")
      self.identityInfo.print()
      print(",")
      self.accountInfo.print()
      print("}")
      sys.stdout = stdout_old
      currdir = os.getcwd()
      os.chdir('..')
      p = subprocess.Popen(args=["./1-submit-access-request",
				"./templates/access-request.json.template",
				self.projectInfo.project.get(),
				self.projectInfo.requestor.get(),
				self.projectInfo.env.get()
			])

      p.communicate()
      # if env == dev, go ahead and provision request w/o waiting for approval
      if self.projectInfo.env.get() == 'dev':
         subprocess.Popen(args=["./2-provision-access-request",
				"./access-request"
			])
      os.chdir(currdir)
      sys.exit(0)
    except ValueError:
      pass

