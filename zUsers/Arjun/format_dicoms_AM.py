"""
This script rearranges data copied off the OSIRIX machine into a
format that dicom2vista_org can handle.

Specifically, this should be called with:

python format_dicoms_AM.py /path/to/session

Where the command line argument is the path to the folder CONTAINING
the Amrit_Alex folder (or whatever the protocol that was run was).

2017-Apr-05 AM wrote it
""" 

import os
import glob
import sys
import shutil

if __name__ == "__main__":
    
    #The full path to the session files is a command-line argument: 
    sess_dir = sys.argv[1]
    if sess_dir[-1]=='/': #If a trailing backslash has been input
        sess_dir=sess_dir[:-1]

    path_pieces = os.path.split(sess_dir)
    sess_name = path_pieces[1]
    print(sess_dir, '\n', path_pieces, '\n', sess_name, '\n')

    os.chdir(sess_dir)
    print(os.path.realpath(os.path.curdir))

    dir_list = os.listdir('.')
    print(dir_list)
    dir_list.remove('.DS_Store')
    print(dir_list)

    if len(dir_list) == 1: # there is only one folder - probably Amrit_Alex (or whatever the protocol was named)
        inner_sess_dir = os.path.join(sess_dir, dir_list[0])
        os.chdir(inner_sess_dir)
        inner_dir_list = os.listdir('.')
        print(inner_dir_list)

        epi_list = []
        gems_list = []
        other_list = []

        for file in inner_dir_list:
            if file.startswith('ep2d'):
                epi_list.append(file)
            elif file.startswith('GEMS'):
                gems_list.append(file)
            else:
                other_list.append(file)

        epi_list.sort() # shouldn't be necessary, but this will guarantee things are in order
        gems_list.sort()
        print(epi_list, gems_list, other_list)

        for i, epifolder in enumerate(epi_list):
            new_name = 'epi_%.2d'%(i+1)
            print('Moving', epifolder, 'to', new_name)
            shutil.copytree(epifolder, '../%s'%new_name)

        for j, gemfolder in enumerate(gems_list):
            new_name = 'gems_%.2d'%(j+1)
            print('Moving', gemfolder, 'to', new_name)
            shutil.copytree(gemfolder, '../%s'%new_name)

        for k, otherfolder in enumerate(other_list):
            print('Moving', otherfolder)
            shutil.copytree(otherfolder, '../%s'%otherfolder)

    """
    dir_list = np.array(os.listdir('.')) 
    #In order to not include '.DS_store'
    epi_list = []
    gems_list = []
    for file in dir_list:
        if file.startswith('epi'):
            epi_list.append(file)
        elif file.startswith('gems'):
            gems_list.append(file)
    dir_list = epi_list + gems_list
    """