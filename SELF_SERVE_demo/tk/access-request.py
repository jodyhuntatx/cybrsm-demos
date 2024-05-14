from loginwin import *
from accessdetail import *

root = Tk()
root.protocol("WM_DELETE_WINDOW", sys.exit)
root.title("CyberArk Access Provisioning Request")
root.columnconfigure(0, weight=1)
root.rowconfigure(0, weight=1)

s = ttk.Style()
s.configure('Cybr.TFrame', background='cornflower blue', borderwidth=5, relief='raised')
s.configure('Cybr.TLabel', background='cornflower blue', borderwidth=5, relief='raised')
s.configure('Cybr.TButton', background='cornflower blue', borderwidth=5, relief='raised')

logoImg = PhotoImage(file='cyberark-logo.png')
logoLabel = ttk.Label(root, image=logoImg, compound='center')
logoLabel.image = logoImg
logoLabel.grid(column=0, row=0, columnspan=5)

LoginWin(root)
AccessRequestDetails(root)
root.mainloop()
