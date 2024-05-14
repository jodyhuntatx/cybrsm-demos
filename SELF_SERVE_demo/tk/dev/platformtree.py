from tkinter import *
from tkinter import ttk
import json

class PlatformTreeView:

  #########################
  # pArray: json array of platform detail records
  def __init__(self, parent, pArray):
    maxWidth = 0
    for plat in pArray:
      if plat["active"] == "true":
        if len(plat["name"]) > maxWidth:
          maxWidth = len(plat["name"])
        
    self.frame = ttk.Frame(parent, borderwidth=5, relief="sunken", width=500, height=300)
    self.frame.grid(column=0, row=0, sticky=(N, W, E, S))
    self.tview = ttk.Treeview(self.frame, height=10, columns=("Platform"))
    self.tview.column("Platform", minwidth=0, width=maxWidth, stretch=YES)
    self.tview.grid(column=0, row=0, sticky=(N, W, E, S))

    for plat in pArray:
      if plat["active"] == "true":
        self.tview.insert('','end',plat["id"],text=plat["name"])
        self.tview.insert(plat["id"],'end',plat,text=plat)
    self.tview.grid(column=0, row=0, sticky=NW)
