'''
homework_5_solution_module.py

'''


def AskForFileName():
    file_name = raw_input ("enter file name ")
    return file_name
    
def ReadFileContents(file_name):
    file=open(file_name)
    data = file.readlines()
    file.close ()
    return data

def BuildHeadList (all_file_contents):
    HeadList = []
    for line in all_file_contents:
        if line.split() [0] == "ATOM":
            return HeadList
        HeadList.append (line)
    return HeadList

def BuildAtomList (all_file_contents):
    atom_list = []
    for line in all_file_contents:
        if line.split() [0] == "ATOM":
            atom_list.append (line)
    return atom_list

def BuildTailList (all_file_contents):
    tail_list = []
    atom_seen = False
    for line in all_file_contents:
        if line.split () [0] == "ATOM":
            atom_seen = True
        elif atom_seen:
            tail_list.append (line)
    return tail_list

def WriteNewFile (head_list, atom_list, tail_list):
    file = open ("output.txt", "w")
    for line in head_list:
        file.write (line)
    for line in atom_list:
        file.write (line)
    for line in tail_list:
        file.write (line)
    file.close ()