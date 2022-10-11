from tkinter import *
from tkinter import ttk
root = Tk()

s = ttk.Style()
s.configure('Danger.TFrame', background='red', borderwidth=5, relief='raised')
df = ttk.Frame(root, width=200, height=200, style='Danger.TFrame').grid()

l = ttk.Label(df, text="Starting...")
l.grid()
l.bind('<Enter>', lambda e: l.configure(text='Moved mouse inside'))
l.bind('<Leave>', lambda e: l.configure(text='Moved mouse outside'))
l.bind('<1>', lambda e: l.configure(text='Clicked left mouse button'))
l.bind('<2>', lambda e: l.configure(text='Clicked right mouse button'))
l.bind('<Double-1>', lambda e: l.configure(text='Double clicked left button'))
l.bind('<Double-2>', lambda e: l.configure(text='Double clicked right button'))
l.bind('<B1-Motion>', lambda e: l.configure(text='Left button drag to %d,%d' % (e.x, e.y)))
l.bind('<B2-Motion>', lambda e: l.configure(text='Right button drag to %d,%d' % (e.x, e.y)))

phone = StringVar()
home = ttk.Radiobutton(df, text='Home', variable=phone, value='home')
office = ttk.Radiobutton(df, text='Office', variable=phone, value='office')
cell = ttk.Radiobutton(df, text='Cell', variable=phone, value='cell')
home.grid(sticky=W)
office.grid(sticky=W)
cell.grid(sticky=W)

root.mainloop()
