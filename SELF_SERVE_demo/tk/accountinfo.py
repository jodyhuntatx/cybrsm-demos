from tkinter import *
from tkinter import ttk
import json

class AccountInfo:

  #########################
  # pArray: json array of platform detail records
  def __init__(self, parent):
    accountFrame = ttk.LabelFrame(parent, text='Account Info', padding="3 3 12 12")
    accountFrame.grid(column=0, row=0, sticky=(N, W, E, S))
    accountFrame.columnconfigure(0, weight=1)
    accountFrame.rowconfigure(0, weight=1)

    with open("platforms.json") as file:
      pList= json.load(file)

    pArray = pList["platforms"]
    maxWidth = 0
    for plat in pArray:
      if plat["active"] == "true":
        if len(plat["name"]) > maxWidth:
          maxWidth = len(plat["name"])
    maxWidth = maxWidth * 2
        
#    self.frame = ttk.Frame(accountFrame, borderwidth=5, relief="sunken", width=500, height=300)
#    self.frame.grid(column=0, row=0, sticky=(N, W, E, S))

    self.tview = ttk.Treeview(parent, height=10, columns=('platform','details'))
    self.tview.column("platform", minwidth=0, width=maxWidth, stretch=YES)
    self.tview.column("details", minwidth=0, width=maxWidth, stretch=YES)
    self.tview = ttk.Treeview(accountFrame, height=10)
    self.tview.grid(column=0, row=0, sticky=(N, W, E, S))

    for plat in pArray:
      if plat["active"] == "true":
        self.tview.insert('','end',plat["id"],text=plat["name"])
        self.tview.insert(plat["id"],'end',plat,text=plat)
    self.tview.grid(column=0, row=0, sticky=NW)


  #########################
  def print(self):
      print("\"accountRequests\": ")
      print(json.dumps(self.tview.selection(), indent=2))
