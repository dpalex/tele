function cluster_vector_to_matrix, cluster_vector ,n_1 , n_2

    matrix = byte(reform(cluster_vector + 1,[n_1,n_2]))
    return , matrix
    
end

function compute_distance, x , y , m_type

; Calcola la distanza di due vettori utilizzando la funzione DISTANCE_MEASURE.
; Data è un vettore N x M che rappresenta le N coordinate di M oggetti.
; Di default viene utilizzata una distanza Euclidea come metrica 
; ? DISTANCE_MEASURE

  data = [[x] , [y]]
  if n_elements(m_type) eq 0 then m_type = 0
  distance = DISTANCE_MEASURE(data,MEASURE = m_type)

  return, distance
 
end

pro assign_pixel_to_cluster , vector_image , tag_vector, centers , min_distance  , numCluster , pixel

      ;Procedura che calcola la distanza dai centroidi ed il pixel, 
      ;In base alla distanza viene assegnato il pixel al custer più vicino

        FOR k = 0,numCluster - 1 DO BEGIN
            
              ;calcolo la distanza tra il pixel ed il cluster center
              distance = compute_distance(transpose(vector_image[pixel,*]),transpose(centers[k,*]))
              
              ;assegno il pixel al cluster più vicino
              IF (min_distance lt 0 OR (distance lt min_distance)) THEN BEGIN         
               min_distance = distance
               tag_vector[pixel]= k        
              ENDIF
                      
           ENDFOR
    
end

function randomCenters, imageVector, numClusters
  dimensions = size(imageVector)
  numPixels = dimensions[1]
  numFeatures = dimensions[2]
  indices = round(numPixels*RANDOMU(seed,numClusters))
  centers = make_array(numClusters,numFeatures,/DOUBLE)
  
  
  FOR i=0 ,numClusters - 1 DO BEGIN
  
  centers[i,*] = imageVector[indices[i],*]
  
  ENDFOR
  return, centers
end

pro updateMean, centers, numClusters, accumulator, counter

  for k= 0,numClusters-1 do begin
       centers[k,*] = double(accumulator[k,*]) / (counter[k])
    endfor
end

pro save_as_envi_classification, classification_matrix,numClusters,filePath,pca,map_info,to_memory

color_vector =  make_array(3, numClusters+1,/LONG)
class_name_vector = make_array(numClusters+1,/STRING)

FOR i = 0,numClusters DO BEGIN

 
  IF (i eq 0) THEN BEGIN
  
  ENVI_GET_RGB_TRIPLETS, 0 ,r,g,b
  color_vector[*,i]=[r,g,b]
  class_name_vector[i]='Unclassified'
 
  ENDIF ELSE BEGIN
  
    ENVI_GET_RGB_TRIPLETS, i+1 ,r,g,b
    color_vector[*,i]=[r,g,b]
    class_name_vector[i]='Class'+STRTRIM(i,2)
     
  ENDELSE
   
                   
ENDFOR 


ENVI_WRITE_ENVI_FILE, classification_matrix $

     , OUT_NAME=filePath $
     , DESCRIP = 'Classification of: '+filePath+' using myKmeans-'+pca $
     , BNAMES = 'MyKmeans-Classification' $
     , FILE_TYPE= 3 $ ;ENVI CLASSIFICATION
     , NUM_CLASSES = numClusters + 1 $
     , LOOKUP = color_vector $
     , CLASS_NAMES = class_name_vector $
     , MAP_INFO = map_info $
     , IN_MEMORY = to_memory


end