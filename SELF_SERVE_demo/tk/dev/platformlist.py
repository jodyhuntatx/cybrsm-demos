from tkinter import *
from tkinter import ttk
import json

class PlatformListBox:

  
  #########################
  # pArray: json array of platform details
  def __init__(self, parent, pArray):
    maxWidth = 0
    self.activePlatformsDetails = []
    activePlatformsList = [] 
    for plat in pArray:
      if plat["active"] == "true":
        self.activePlatformsDetails.append(plat)
        activePlatformsList.append(plat["name"])
        if len(plat["name"]) > maxWidth:
          maxWidth = len(plat["name"])
        
    self.frame = ttk.Frame(parent, padding="10 10 10 10")
    self.frame.grid(column=0, row=0, sticky=(N, W, E, S))
    platformsVar = StringVar(value=activePlatformsList)
    self.lbox= Listbox(self.frame, height=10, width=maxWidth, listvariable=platformsVar)
    self.lbox.bind("<<ListboxSelect>>",
	   lambda e: self.printPlatformDetails(self.lbox.curselection()))
    self.lbox.grid(column=0, row=0, sticky=NW)

  #########################
  def printPlatformDetails(self, platIdx):
    print(json.dumps(self.activePlatformsDetails[platIdx[0]], indent=2))

