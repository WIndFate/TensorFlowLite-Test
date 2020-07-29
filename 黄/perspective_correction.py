import numpy as np
import cv2 as cv
import os
from segm_box_model import cfg


def get_pred_min_rect_coord(input_img, segm_mask, factor=5, enlarge=False, threshold=0.8, min_grid_size=3):
    """
    adapted version of this post_processing.visualize_bb_pred() 
    it fits a minimum area rectangle for each mask in the image
    and returns the min_area rectangle coordinates in a list

    Parameters:
    input_img: image array of dimension (H, W, 3)
    segm_mask: mask array of dimension (H, W, 1)
    threshold: segmentation threshold [0,1]
    ming_grid_size: neglect grids which are smaller than this, in segm units  
    """

    img = input_img.copy()
    segm_c = segm_mask.copy()

    # These are the parameters to control the the creation
    # of the boxes from the segmentation mask
    threshold_level = int(255*threshold)
    scaling = 0.7
    extend_multiplier = 1.1

    # map the grid size to the real image dimensions
    min_box_area = cfg.GRID_SIZE*cfg.GRID_SIZE*min_grid_size

    # scale and convert to cv type
    image_8bit = np.uint8(np.squeeze(segm_c) * 255)

    # original image
    orig_img = np.squeeze(img)

    # binarize
    _, binarized = cv.threshold(
        image_8bit, threshold_level, 255, cv.THRESH_BINARY)

    # find contours, Note that openCV returns 3 things here!
    contours, hierarchy = cv.findContours(
        binarized, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)

    # scale to original image dims
    contours = [contour*cfg.GRID_SIZE for contour in contours]

    min_rect_coord_list = []
    # fit min area bounding rectangle and return the rectangle coordinates
    for contour in contours:
        rect = cv.minAreaRect(contour)
        # get the four verstices of a rotated rectangle
        box = cv.boxPoints(rect)
        box = np.int0(box)
        if enlarge == True:
#             print('min_area rect before', box)
            # enlarge the min_area rectangle for better end result
            # need to comment the enlargement code out to make draw contour work
            tl, tr, br, bl = order_coord(box)
            tl[0] -= factor
            tl[1] -= factor
            tr[0] += factor
            tr[1] -= factor
            bl[0] -= factor
            bl[1] += factor
            br[0] += factor
            br[1] += factor
            box = np.array([tl, tr, br, bl])
#             print('min_area rect after enlarging', box)
        min_rect_coord_list.append(box)

    return min_rect_coord_list


def order_coord(coord):
    """
    in order to calculate the perspective transform matrix, which is used in 
    perspective correction, coordinates of the min_area rectangles have to follow 
    the following order: top-left, top-right, bottom-right, bottom-left

    this function guarantees that coordinates fed into four_point_transform(image, coord)
    follow the order specified above

    Parameters:
    coord: coordinate of the min_area rectangle that's fitted on the segmentation mask     

    Returns:
    rect: coordinate of the min_area rectangle ordered in the way explained above
    """
    rect = np.zeros((4, 2), dtype="float32")
    # sum of the top-left point coordinate is the smallest
    # sum of the bottom-right point coordinate is the largest
    s = coord.sum(axis=1)
    rect[0] = coord[np.argmin(s)]
    rect[2] = coord[np.argmax(s)]
    # compute the difference between the point coordinates, the
    # top-right point coordinate has the smallest difference,
    # whereas the bottom-left point has the largest difference
    diff = np.diff(coord, axis=1)
    rect[1] = coord[np.argmin(diff)]
    rect[3] = coord[np.argmax(diff)]

    return rect


def four_point_transform(img, coord):
    """
    use perspective transform matrix to correct the perspective of an image given four points on it
    the four points correspond to the coordinates of the min_area rectangle on the segmentation mask

    Parameters:
    img: image array of dimension (H, W, 3) whose perspective needs correction
    coord: coordinate of the min_area rectangle that's fitted on the segmentation mask

    Returns:
    corrected: perspective corrected image 
    dst: coordinates of the mask of on the corrected image
    """
    rect = order_coord(coord)
    tl, tr, br, bl = rect

    # define the dimension of the mask on the perspective corrected image
    # its height will be the minimum distance between the top-right and bottom-right
    # y-coordinates and the top-left and bottom-left y-coordinates
    heightA = np.sqrt(((tr[0] - br[0]) ** 2) + ((tr[1] - br[1]) ** 2))
    heightB = np.sqrt(((tl[0] - bl[0]) ** 2) + ((tl[1] - bl[1]) ** 2))
    height = min(int(heightA), int(heightB))
    # TODO: change this hard coded aspect ratio to an input argument
    ratio = 4.7
    width = height*ratio

    # use the dimension from above to calculate the destination coord of the mask
    # that will have a birds eye view
    # dst coord has the same order as before: top-left, top-right, bottom-right, and bottom-left
    dst = np.array([
        [tl[0], tl[1]],
        [tl[0]+width, tl[1]],
        [tl[0]+width, tl[1]+height],
        [tl[0], tl[1] + height]], dtype="float32")
    # print(rect)
    # print(dst)

    # compute the perspective transform matrix and apply it on the image that needs perspective transformation
    M = cv.getPerspectiveTransform(rect, dst)
    corrected = cv.warpPerspective(img, M, (img.shape[1], img.shape[0]))

    return corrected, dst


def crop_for_text(corrected_img, dst_coord):
    """
    crop the area covered by the mask from the perspective corrected image

    Parameters:
    corrected_img: perspective corrected image array of dimension (H, W, 3) 
    dst_coord: coordinate of the mask on the perspective corrected image, whose points follow the following order
    top-left, top-right, bottom-right, bottom-left
    """
    tl, tr, br, bl = dst_coord

    cropped_text = corrected_img[int(tl[1]):int(
        bl[1]+1), int(tl[0]):int(tr[0]+1), :]

    return cropped_text


def get_text_crops_multi_img(batch_img, batch_mask):
    """ 
    crop the mask covered text from one perspective corrected image
    and return all the crops in a list

    Parameters:
    batch_img: array(N, H, W, 3) of images whose perspective need correction
    batch_mask: array(N, H, W, 1) of masks corresponding to the input images

    Returns:
    cropped_text: a list of arrays that contains the crops of text from the perspective corrected images
    """
    cropped_text = []
    for i in range(len(batch_img)):
        img, mask = batch_img[i], batch_mask[i]
        # get the min_area rectangle coordinates from the mask
        min_rect_coord_list = get_pred_min_rect_coord(
            img, mask, threshold=0.8, min_grid_size=3)
        print(len(min_rect_coord_list))
        for j in range(len(min_rect_coord_list)):
            # perspective correction returns the corrected image and min_area rectangle location
            corrected_img, dst = four_point_transform(
                img, min_rect_coord_list[j])
            # crop the text out using the corrected min_area rectangle coordinate
            cropped = crop_for_text(corrected_img, dst)
            cropped_text.append(cropped)

    return cropped_text
