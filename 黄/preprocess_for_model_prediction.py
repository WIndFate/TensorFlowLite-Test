import numpy as np
import os
from PIL import Image

def load_images(img_path_list=None, use_folder=True, folder="inference_test_imgs/2020_07_16_test_data"):
    #loads all images in a folder to a list
    curr_parent_dir = os.path.dirname(os.getcwd())
    inference_dir = os.path.join(curr_parent_dir,folder)
    # print(sorted(os.listdir(inference_dir)))
    pil_images = []
    if not use_folder:
        for path in img_path_list:
            #read the image
            img = Image.open(path)
            pil_images.append(img)

        return pil_images, img_path_list

    else:
        for filename in sorted(os.listdir(inference_dir)):
            #read the image
            filepath = os.path.join(inference_dir,filename)
            img = Image.open(filepath)
            pil_images.append(img)
        # [os.path.join(inference_dir, i) for i in sorted(os.listdir(inference_dir))]
        return pil_images, sorted(os.listdir(inference_dir))

 
def preprocess_batch_imgs(pil_images, img_h, num_ds=2, img_w=256, preprocess = False):
    
    imgs_list_arr = []

    #resize the images to the correct height while mainting ratio
    for ind, img in enumerate(pil_images):

        w, h = img.size
        resize_scale = h / img_h
        new_w = w / resize_scale

        pil_images[ind] = img.resize((int(new_w), int(img_h)), Image.ANTIALIAS)

    # check the largest image width in the batch
    max_width = max([img.size[0] for img in pil_images])

    #scaling factor from image height to the height after
    #convolutions in the image
    scaling_factor = 2**num_ds

    #process the batch
    for batch_ind, pil_img in enumerate(pil_images):

        # pad the image width with to the largest (fixed) image width
        width, height = pil_img.size

        new_img = Image.new(pil_img.mode, (img_w, img_h), (255,255,255))
        new_img.paste(pil_img, ((img_w - width) // 2, 0))

        # check if PIL image has four channels, if true, only keep the first three 
        img_arr = np.array(new_img)
        _,_,c = img_arr.shape
        if c == 4:
            img_arr = img_arr[...,:3]

        if preprocess:
            img_arr = sharpen(img_arr)
            # gray_img = cv2.cvtColor(img_arr, cv2.COLOR_RGB2GRAY)
            img_arr = hist_equalize(img_arr)
            # img_arr = skimage.color.gray2rgb(img_arr)

        # convert to numpy array, scale with 255 so that the values are between 0 and 1
        # and save to batch, also transpose because the "time axis" is width
        img_arr = np.array(img_arr).transpose((1,0,2)) / 255

        imgs_list_arr.append(img_arr)
    
    #make the input lengths corresponding the time distributed length from
    #NN prediction for the ctc_decode funtion
    t_dist_len = int(img_w/(2**num_ds))
    input_length = np.full((len(pil_images)), t_dist_len, dtype=int)

    return np.array(imgs_list_arr), input_length


img_h = 24
num_ds = 2
folder = '/work/inference_test_imgs/demo_ocr_test_data/'
img_path_list = [os.path.join(folder, 'barcode_test_1_orig_cropped.jpg')]
use_folder = False
preprocess = False

pil_images, img_path = load_images(img_path_list, use_folder, folder=folder)
imgs_array, input_length = preprocess_batch_imgs(pil_images, img_h, num_ds, preprocess = preprocess)

# # prediction using keras model 
# y_preds = model.predict(imgs_array)

# convert data type to float32 for tf lite model 
input_data = imgs_array.astype('float32')

