from lxml.etree import Element, SubElement, tostring
import pprint
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET
import cv2 as cv
import numpy as np
import matplotlib.pyplot as plt
import os
from segm_box_model import cfg, perspective_correction


def to_pascal_xml_str(bboxes, filename, w='800', h='1000'):
    """function to write the text bboxes into xml format
    """
    node_root = Element('annotation')
    node_folder = SubElement(node_root, 'folder')
    node_folder.text = 'images'
    node_filename = SubElement(node_root, 'filename')
    node_filename.text = filename
    node_size = SubElement(node_root, 'size')
    node_width = SubElement(node_size, 'width')
    node_width.text = w
    node_height = SubElement(node_size, 'height')
    node_height.text = h
    node_depth = SubElement(node_size, 'depth')
    node_depth.text = '3'
    for b in bboxes:
        node_object = SubElement(node_root, 'object')
        node_name = SubElement(node_object, 'name')
        node_name.text = 'word'
        node_difficult = SubElement(node_object, 'difficult')
        node_difficult.text = '0'
        node_bndbox = SubElement(node_object, 'bndbox')
        node_xmin = SubElement(node_bndbox, 'xmin')
        node_xmin.text = str(int(b[0]))
        node_ymin = SubElement(node_bndbox, 'ymin')
        node_ymin.text = str(int(b[1]))
        node_xmax = SubElement(node_bndbox, 'xmax')
        node_xmax.text = str(int(b[2]))
        node_ymax = SubElement(node_bndbox, 'ymax')
        node_ymax.text = str(int(b[3]))
    xml = tostring(node_root, pretty_print=True)  #格式化显示，该换行的换行
    dom = parseString(xml)
    return xml


def visualize_bb_pred(input_img, segm_mask, threshold=0.8, min_grid_size=3):
    """
    Function to visualize/generate the bounding boxes for
    input_img: the input image to the NN
    semg_mask: corresponding output from the NN
    threshold: segmentation threshold [0,1]
    ming_grid_size: neglect grids which are smaller than this, in segm units
    """

    img = input_img.copy()
    segm_c = segm_mask.copy()
    
    #These are the parameters to control the the creation
    #of the boxes from the segmentation mask
    threshold_level = int(255*threshold)
    scaling = 0.7
    extend_multiplier = 1.1
    
    #map the grid size to the real image dimensions
    min_box_area = cfg.GRID_SIZE*cfg.GRID_SIZE*min_grid_size

    #scale and convert to cv type
    image_8bit = np.uint8(np.squeeze(segm_c) * 255)

    #original image
    orig_img = np.squeeze(img)

    #binarize
    _, binarized = cv.threshold(image_8bit, threshold_level, 255, cv.THRESH_BINARY)

    #find contours, Note that openCV returns 3 things here!
    contours, hierarchy = cv.findContours(binarized, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)

    #scale to original image dims
    contours = [contour*cfg.GRID_SIZE for contour in contours]

    #fit bounding rectangle and draw to pic
    for contour in contours:
        (x,y,w,h) = cv.boundingRect(contour)

        #make the boxes slightly bigger since the original segmentation is done on shrinked boxes
        min_wh = min(w,h)
        
        if w*h < min_box_area:
            continue
        
        x = x - int(min_wh*scaling/2)
        w = w + int(min_wh*scaling*extend_multiplier)
        y = y - int((min_wh*scaling/2))
        h = h + int((min_wh*scaling)*extend_multiplier)

        cv.rectangle(orig_img, (x,y), (x+w,y+h), (0,0,255), 2)

    plt.figure(figsize=(35,35))
    plt.imshow(orig_img)


def make_xml_pred(input_img, segm_mask,filepath, imsize_hw, threshold=0.8,min_grid_size=3):
    """Function to make the xml annotation files for the original images
    input_img: the input image to the NN
    semg_mask: corresponding output from the NN
    threshold: segmentation threshold [0,1]
    min_grid_size: neglect grids which are smaller than this, in segm units
    filepath: path of the original img so that the xml goes to correct place
    imsize_hw: original image (heigh,width)
    """
    img = input_img.copy()
    segm_c = segm_mask.copy()

    #These are the parameters to control the the creation
    #of the boxes from the segmentation mask
    threshold_level = int(255*threshold)
    scaling = 0.7
    extend_multiplier = 1.1

    #map the grid size to the real image dimensions
    min_box_area = cfg.GRID_SIZE*cfg.GRID_SIZE*min_grid_size
    
    #the scaling factors from the original to the one fed to the NN
    resizef_h = imsize_hw[0]/img.shape[0]
    resizef_w = imsize_hw[1]/img.shape[1]

    #scale and convert to cv type
    image_8bit = np.uint8(np.squeeze(segm_c) * 255)

    #original image
    orig_img = np.squeeze(img)

    #binarize
    _, binarized = cv.threshold(image_8bit, threshold_level, 255, cv.THRESH_BINARY)

    #find contours, note that openCV returns 3 things here!
    contours, hierarchy = cv.findContours(binarized, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)

    #scale to original image dims
    contours = [contour*cfg.GRID_SIZE for contour in contours]
    
    #make a list in a format which can be utilized by the xml script
    bboxes = []

    #fit bounding rectangle and draw to pic
    for contour in contours:
        (x,y,w,h) = cv.boundingRect(contour)

        if w*h < min_box_area:
            continue

        #for the xmin..ymax
        b = np.zeros((4))
        
        #make the boxes slightly bigger since the original segmentation is done on shrinked boxes
        min_wh = min(w,h)
        x = x - int(min_wh*scaling/2)
        w = w + int(min_wh*scaling*extend_multiplier)
        y = y - int((min_wh*scaling/2))
        h = h + int((min_wh*scaling)*(extend_multiplier))
        
        b[0] = x*resizef_w
        b[1] = y*resizef_h
        b[2] = (x + w)*resizef_w
        b[3] = (y + h)*resizef_h
        
        bboxes.append(b)
  
    filename = os.path.basename(filepath)
    
    #return xml file
    xml = to_pascal_xml_str(bboxes, filename, w=str(imsize_hw[1]), h=str(imsize_hw[0]))

    #save xml
    filepath_xml = filepath[:-4]+'.xml'

    with open(filepath_xml, "w") as text_file:
        print(xml.decode("utf-8"), file=text_file)

    return None


def visualize_polygon_pred(input_img, segm_mask, threshold=0.8, min_grid_size=3):
    """
    Function to visualize/generate the bounding boxes for
    input_img: the input image to the NN
    semg_mask: corresponding output from the NN
    threshold: segmentation threshold [0,1]
    ming_grid_size: neglect grids which are smaller than this, in segm units
    """

    img = input_img.copy()
    segm_c = segm_mask.copy()
    
    #These are the parameters to control the the creation
    #of the boxes from the segmentation mask
    threshold_level = int(255*threshold)
    scaling = 0.7
    extend_multiplier = 1.1
    
    #map the grid size to the real image dimensions
    min_box_area = cfg.GRID_SIZE*cfg.GRID_SIZE*min_grid_size

    #scale and convert to cv type
    image_8bit = np.uint8(np.squeeze(segm_c) * 255)

    #original image
    orig_img = np.squeeze(img)

    #binarize
    _, binarized = cv.threshold(image_8bit, threshold_level, 255, cv.THRESH_BINARY)

    #find contours, Note that openCV returns 3 things here!
    contours, hierarchy = cv.findContours(binarized, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)

    #scale to original image dims
    contours = [contour*cfg.GRID_SIZE for contour in contours]

    #fit bounding rectangle and draw to pic
    for contour in contours:
        arclen = cv.arcLength(contour, True)
        points = cv.approxPolyDP(contour, 0.02*arclen, True)
        if len(points) < 4:
            continue
        # print(points)
        # points = list(map(lambda x: x[0], points))

        # points = sorted(points, key=lambda x:x[1])
        # top_points = sorted(points[:2], key=lambda x:x[0])
        # bottom_points = sorted(points[2:4], key=lambda x:x[0])
        # points = top_points + bottom_points

        # left = min(points[0][0], points[2][0])
        # right = max(points[1][0], points[3][0])
        # top = min(points[0][1], points[1][1])
        # bottom = max(points[2][1], points[3][1])
        # # points = np.array([points[0],points[1],points[2],points[3]]).reshape((-1,1,2)).astype(np.int32)
        # # print(points)
        # print(top_points)
        # pts=np.array([top,bottom,right,left],dtype=int)
        cv.polylines(orig_img, [points], isClosed=True,color=(0,0,255),thickness=2, lineType=4)
        

    plt.figure(figsize=(35,35))
    plt.imshow(orig_img)

    
    
def show_min_rect_bbox(img, segm_mask):
    """
    img: image array of dimension (H, W, 3)
    segm_mask: mask array of dimension (H, W, 1)
    """
    min_rect_coord_list = perspective_correction.get_pred_min_rect_coord(img, segm_mask, threshold=0.8, min_grid_size=3)
    img_copy = img.copy()
    for i in range(len(min_rect_coord_list)):
        cv.drawContours(img_copy, [min_rect_coord_list[i]],0,(0,0,255),2) # min area rectangle
    plt.figure(figsize = (25, 15))
    plt.imshow(img_copy)
    