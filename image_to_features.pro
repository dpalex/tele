function image_to_features, image , READ_TIFF_ORDER

    ;Funzione per organizzare il vettore delle features
    ;La matrice vector_features NxM :
    ;- Pixel (N colonne) 
    ;- Valori delle bande (M righe) 
    
    size_of_image = size(image)
    n_b=min(size_of_image[1:3])
    n_pixel=max(size_of_image)
    vector_features=make_array(n_pixel/n_b,n_b,/UINT)
    
    IF READ_TIFF_ORDER THEN BEGIN
    
      FOR band = 0,n_b - 1 DO BEGIN
        
        spectral_matrix_to_vector = reform(reform(image[band,*,*]),n_pixel/n_b)
        vector_features[*,band]=spectral_matrix_to_vector
                      
      ENDFOR 
      
    ENDIF ELSE BEGIN
    
    print, "File loaded with ENVI"
    
      FOR band = 0,n_b - 1 DO BEGIN
        
        spectral_matrix_to_vector = reform(reform(image[*,*,band]),n_pixel/n_b)
        vector_features[*,band]=spectral_matrix_to_vector
                      
      ENDFOR 
      
    ENDELSE
    
  return, double(vector_features)
  
end