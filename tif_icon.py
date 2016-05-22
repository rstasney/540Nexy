#!python3
#tif_icon.py
#
#   Author: Dakota Ward
#   Class project : ECE 507 Python workshop
#   
#   Description:
#       This program reads a TIFF image and gives the user the ability to:
#           1.Resize the original image
#           2.transpose the image
#           3.print the image to screen 
#           3.split image into seperate RGB channels and place them into numpy arrays
#           4.concatenate RGB arrays 
#           5.save individual R,G,B arrays and/or concatenated RGB array to file
#           in .coe format with header included
#          
######################################################################################################################
#   USAGE:
#           1.line # 178,221 : change the hardcoded path to the names of your own system and sub directory 
#           where you are storing your TIFF images and want to save your output files
#           2.simple text user prompt will guide you through the program
#
#######################################################################################################################    

from __future__ import print_function
from PIL import Image
import os.path
import sys
import numpy as np


#for printing numpy arrays
np.set_printoptions(threshold=np.inf,formatter={'int':hex}) # np.inf:avoids truncation of printing numpy array, format in hexidecimal



def handle_image_conversion(image_filepath):
    '''
    Function: opens image: succesfull open will print out image's dimesnsions
          User will be prompted for resizing image and printing image to screen.
          error handling: exceptions will be thrown if image file not found or misspelling of image file, system will exit
          Returns: image as an Image object
    '''
    image = None
    try:
        image_tif = Image.open(image_filepath)
        #check to see if image opened succesfully
        print(image_tif.format, image_tif.size, image_tif.mode)  #TYPE(width,height)modes = RGB,L(grayscale),CMYK(pre-press)
        choice = input("Would you like to resize the image? Press [y]es or [n]o: ")
        if choice == 'y':
            resized_tif = resize_image(image_tif)
            print_image(resized_tif)
            return resized_tif
        else:
            print_image(image_tif)
            return image_tif

    except Exception as e: #exception block for image open error
        print ("Unable to open image file {image_filepath}.".format(image_filepath=image_filepath))
        print (e)
        sys.exit()
   

def print_image(image):
    '''
    Function: with user prompt, prints image to scrren
              Returns: nothing
    '''
    print_option = input("Print Image to Screen? Press [y]es or [n]o: ")
    if print_option == 'y':
        image.show()
    else:
        return

def resize_image(image):
    '''
        Function: prompts user for new pixel height/width dimensions
              Resizes image using the NEAREST filter
              Returns: resized image
    '''    
    width = int(input("Enter the new pixel width: "))
    height = int(input("Enter the new pixel height: "))
    resized_image = image.resize((width,height),Image.NEAREST)  # resize((tuple(width),tuple(height)), filter NEAREST:Pick the nearest pixel from the input image. Ignore all other input pixels
    print(resized_image.format, resized_image.size, resized_image.mode)
    return resized_image

def split_into_rgb_channels(image):
    '''
        Function:Splits the target image into its red, green and blue channels.
                 image - a numpy array of shape (rows, columns, 3).
                 Returns: three numpy arrays of shape (rows, columns) and dtype same as
                 image, containing the corresponding channels. 
    '''
    red = image[:,:,0]
    green = image[:,:,1]
    blue = image[:,:,2]
    return red, green, blue


def transpose_menu():
    '''
        Function: Submenu for transpose options
                  Returns: NONE -- takes no parameters and returns nothing
    '''
    print (30 * "-" , "TRANSPOSE MENU" , 30 * "-")
    print ("1. FLIP_LEFT_RIGHT")
    print ("2. FLIP_TOP_BOTTOM")
    print ("3. ROTATE_90")
    print ("4. ROTATE_180")
    print ("5. ROTATE_270")
    print (76* "-")


def transpose(image, selection):
    '''
    Function: case statement for transpose options
              Returns: Image object that has been transposed
    '''
    if selection == '1':
        out = image.transpose(Image.FLIP_LEFT_RIGHT)
    elif selection == '2':
        out = image.transpose(Image.FLIP_TOP_BOTTOM)
    elif selection == '3':
        out = image.transpose(Image.ROTATE_90)
    elif selection == '4':
        out = image.transpose(Image.ROTATE_180)
    elif selection == '5':
        out = image.transpose(Image.ROTATE_270)
    else:
        print("invalid selection! Select 1-5 for image transpose")
        sys.exit()
    return out


def split_rgb(image):
    '''
    Function: Takes Image object as parameter
              Returns: 3 numpy arrays with R, G, B channels 
    ''' 
    #convert file to numpy array
    data = np.array(image)#,dtype='uint8') **dtype is already identified, redundant 
    #split images into RGB channels
    red, green, blue = split_into_rgb_channels(data)
    return red, green, blue


def divideBy16(array):
    
    '''
        Function: Divides decimal numpy array by 16 creating an array with elements ranging from (0-F) hex
                  Returns: numpy array
    '''
    new = np.floor_divide(array,16) #floor division required to avoid floating point 
    return new


def prepare_rgb_arrays(t_array):
    '''
        Function: wrapper for split_rgb(array) & divideby16(array) functions
                  Returns: 3 numpy arrays
    '''
    #divide by 16 and save RGB data to file
    red_dat,grn_dat,blu_dat =split_rgb(t_array)
    red_arr =divideBy16(red_dat)
    green_arr = divideBy16(grn_dat)
    blue_arr = divideBy16(blu_dat)
    return red_arr,green_arr,blue_arr


def saveToFile(array,message):
    '''
    Function: parameters: array, and message number
              Prompts user for filename to save with appropriate message(cue) for the specific
              R, G, B, or Concatenated file
              Returns: nothing
    '''
    savePath = 'C:/Users/Dakota/Desktop/TIF_icon/COE/'  #inout/image file path
    header_string ="MEMORY_INITIALIZATION_RADIX=16;\nMEMORY_INITIALIZATION_VECTOR=\n" #header for .coe file
    footer_string = ';'

    #user prompt
    if message == 1:
        save_file = input("What is the name of your Red channel output file?")
    elif message == 2:
        save_file = input("What is the name of your Green channel output file?")
    elif message == 3:
        save_file = input("What is the name of your Blue channel output file?")
    elif message == 4:
        save_file = input("What is the name of your Concatenated RGB output file?")
        save_file_path = os.path.join(savePath, save_file) 
        with open(save_file_path,'w') as f:
            f.write(header_string)
            f.write(",".join(array))
            f.write(footer_string)
            f.close()
            sys.exit()

    save_file_path = os.path.join(savePath, save_file) 
    with open(save_file_path,'w') as f:
        f.write(header_string)
        array.tofile(f,sep=",", format ="%x")
        f.write(footer_string)
        f.close()
       
        # np.savetxt(f,array,delimiter=' ',newline=' ',fmt='%i', #format in hexadecimal
       #               header=header_string,footer=footer_string) #header created, footer appended

        
def save_options(r_array,g_array,b_array):
    '''
        Function: wrapper for saveToFile(array,message) function 
        User prompted with choices to save individual RGB arrays as .coe files or concatenate RGB channel
        arrays into one .coe file
        Returns: nothing
    '''
    save_option = input ("Would you like to generate seperate R,G,B .coe files?\nEnter [y]es or [n]: ")
    if save_option == 'y':
        saveToFile(r_array,1)
        saveToFile(g_array,2)
        saveToFile(b_array,3)
    else:
        pass
    save_concat = input ("Would you like to concatenate the RGB data to one .coe file?\nEnter [y]es ot [n]: ")
    if save_concat == 'y':

        concate_array = np.dstack((r_array,g_array,b_array)) 
        new_concat_list = [' '.join([hex(ele) for ele in row]) for dim in concate_array for row in dim]
        number_of_elements = len(new_concat_list)
        for i in range(0,number_of_elements):
            new_concat_list[i] = new_concat_list[i].replace(' ', '').replace('0x', '')
        
        saveToFile(new_concat_list,4)
    else:
        print("Closing program.....")
        sys.exit()


def main():
    
    imgPath = 'C:/Users/Dakota/Desktop/TIF_icon/TIFS/'  #image file path CHANGE AS NEEDED 
    
    #user prompt
    image_file = input("What is the name of your TIF file?")
    image_file_path = os.path.join(imgPath, image_file)
    
    #open image
    newImage = handle_image_conversion(image_file_path)
   
    #loop variables 
    loop = True
    global flip #variable to persist through while loop
    
    #loop through transpose/print image to screen options
    while loop:
        option_transpose = input("Do you need to transpose the image? \npress [y]es or [n]o: ")
        if option_transpose == 'y':
            transpose_menu()
            transpose_choice = input("Enter your choice [1-5]: ")
            flip = transpose(newImage,transpose_choice) 
            print_image(flip)
            red1, green1, blue1 = prepare_rgb_arrays(flip)  
            save_options(red1,green1,blue1)  
        elif option_transpose == 'n':
            loop=False  #exit loop
        else:
            input("Wrong option selection. Enter [y]es ot [n]o..")
        
        #No transpose selected, use original loaded image (newImage)
        red1, green1, blue1 = prepare_rgb_arrays(newImage) #split RGB channels into 3 seperate numpy arrays
        save_options(red1,green1,blue1) # save seperate RGB channel files and/or concatenate the RGB arrays into one file

    #else:#The image has been transposed
     #   red1, green1, blue1 = prepare_rgb_arrays(flip)  
      #  save_options(red1,green1,blue1) 

        
if __name__=='__main__':
    main()
    
    