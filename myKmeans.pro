function myKmeans, image, numCluster , threshold , max_iteration , pca , th_pca

      ;Init delle variabili di dimensione
      size_image = size(image)
      number_of_bands =min(size_image[1:3]) ; Numero di bande
      
      ;La funzione READ_TIFF e la funziona di LOAD di ENVI organizzano l'immagine con un
      ;ordine delle dimensione diverse, per discriminare quale sia l'ordine si utilizza questo IF

      IF (size_image[1] eq number_of_bands) THEN BEGIN         
               number_1_dimension = size_image[2]
               number_2_dimension = size_image[3]
               READ_TIFF_ORDER = 1B
      ENDIF ELSE  BEGIN
               number_1_dimension = size_image[1]
               number_2_dimension = size_image[2]
               READ_TIFF_ORDER = 0B       
      ENDELSE
       
      number_pixel = number_1_dimension*number_2_dimension; Numero di pixel per ogni dimensione
      
      print, 'Number di bande:'
      print, number_of_bands
      print, 'Number di pixel:'
      print, number_pixel
      
      number_of_features = number_of_bands
           
      ;Trasforma l'immagine BxNxM in una matrice di B righe ed N colonne rappresentati i pixel 
      print, 'Reordening image in features vector...' 
      vector_image = image_to_features(image,READ_TIFF_ORDER)
      print, 'Done'  
      
      
      ;Utilizza l'algoritmo PCA
      IF (pca) THEN BEGIN
       print, 'Reduce features using PCA based alghoritm...' 
       print, 'Pca % : ',th_pca
       pca_features = mypca(vector_image[*,*],th_pca)
       vector_image = pca_features
       v_s=size(vector_image)
       number_of_features = v_s[2]
       print, 'Done'   
      ENDIF
      
      ;Init del vettore di output della stessa dimensione dei pixel
      tag_vector = make_array(number_pixel,/UINT)
      
      ;Init dei centroidi scelti casualmente
      centers = randomCenters(vector_image,numCluster)
      print, 'Centroidi init: '
      print ,centers
      
      ;Init variabili per update della media e fine while
      
      accumulator = make_array(numCluster,number_of_features,/DOUBLE)
      counter = make_array(numCluster,/DOUBLE)
      number_cycle = 0
      
      ;Inizializza gli elementi ad un valore non ottenibile
      ;Viene utilizzato per tenere traccia del numero di pixel riassegnati
      ;ad ogni iterazione
      pre_tag_vector = make_array(number_pixel,/UINT) - 1 
      
      ;Init variabilidi End condition del while
      keepgoing = byte(1)
      number_changed_pixel = 0UL
      min_changed = round(float(number_pixel) * threshold)
      
      print,'Minime riassegnazioni:  ', min_changed        
      print,'Massime iterazioni:  ', max_iteration
      print, 'START'
      ;main loop
      WHILE keepgoing DO BEGIN
      pixel=0UL
      
      ; Per ogni pixel
      WHILE pixel lt number_pixel DO BEGIN
         ;Init distanza
          min_distance = -1.0
            
          ;Routine che assegna il pixel alla classe  
          assign_pixel_to_cluster , vector_image , tag_vector, centers , min_distance  , numCluster , pixel
          
          ;Aggiorno l'accumilatore ed il counter
          accumulator[tag_vector[pixel],*] = accumulator[tag_vector[pixel],*] + vector_image[pixel,*]
          counter[tag_vector[pixel]] = counter[tag_vector[pixel]] + 1
          ;Incremento l'indice di pixel
          pixel = pixel +1
        
       ENDWHILE
        ;Fine while pixel , ogni pixel è stato assegnato ad un cluster
        
        ;Aggiorno i centroidi
        updateMean, centers, numCluster , accumulator, counter
        
        ;Riazzero gli accumulatori
        accumulator = make_array(numCluster,number_of_features,/DOUBLE)
        counter = make_array(numCluster,/DOUBLE)
        
        ; Aggiorno i valori
        number_cycle = number_cycle + 1
        
        IF array_equal(pre_tag_vector,tag_vector) ne 1 THEN BEGIN
        
         diff_vector_index_size = size(WHERE(pre_tag_vector ne tag_vector))
         number_changed_pixel = diff_vector_index_size[3]      
         
        ENDIF ELSE BEGIN
        
        number_changed_pixel=0
        
        ENDELSE
     
        
        ;Continuo se non ho raggiunto il massimo delle iterazioni 
        ;e se ho cambiato un numero sufficiente di pixel
        ;definito dal threshold
        keepgoing = (number_cycle lt max_iteration) AND (number_changed_pixel gt min_changed )
        
        print, 'Numero di pixel assegnati ad un nuovo cluster: ', number_changed_pixel
        print, 'Fine iterazione numero: ', number_cycle
        number_changed_pixel = 0UL
        pre_tag_vector = tag_vector

      ENDWHILE
      
      print, 'END'
      return , cluster_vector_to_matrix(tag_vector[*],number_1_dimension,number_2_dimension)
      
end