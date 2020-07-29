
def need_rotation(min_rect_coord, img_arr):
#     print(min_rect_coord)
    tl, tr, br, bl = min_rect_coord
    x_length = tr[0] - tl[0]
    y_length = bl[1] - tl[1]
    
    h, w, _ = img_arr.shape
    # if x_length < y_length and the image is a landscape, rotation is needed 
    # else do not rotate
    return (x_length < y_length) and (h < w) 


# both img and mask are three dimentional array of shape
# (h, w, 3) and (h, w, 1)


# get the min_area rectangle coordinates from the mask
# get bigger crops by changing the factor argument in perspective_correction.get_pred_min_rect_coord
min_rect_coord_list = perspective_correction.get_pred_min_rect_coord(
    img, mask, factor=7, enlarge=True, threshold=0.8, min_grid_size=3)

for j in range(len(min_rect_coord_list)):
    reordered = perspective_correction.order_coord(min_rect_coord_list[j])

    if need_rotation(reordered, img):
        rotated.append(img_name_list[i])
        img = np.rot90(img)

        mask = np.rot90(mask)
        min_rect_coord_list = perspective_correction.get_pred_min_rect_coord(img, mask, factor=factor, enlarge=True, 

    # perspective correction returns the corrected image and min_area rectangle location
    corrected_img, dst = perspective_correction.four_point_transform(
        img, min_rect_coord_list[j])

    # crop the text using the corrected min_area rectangle coordinate
    cropped = perspective_correction.crop_for_text(corrected_img, dst)