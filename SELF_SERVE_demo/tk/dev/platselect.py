from tkinter import *
from tkinter import ttk
import json

import platformlist
from platformlist import PlatformListBox
import platformtree
from platformtree import PlatformTreeView

with open("platforms.json") as file:
  platformList = json.load(file)

root = Tk()
root.title("Platforms")
root.columnconfigure(0, weight=1)
root.rowconfigure(0, weight=1)
plb = PlatformTreeView(root, platformList["platforms"])
root.mainloop()
