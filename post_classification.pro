function confusion_matrix, predict, reference , numClusters
    
    ;Initi della confusion matrix di dimensione numClusters X numClusters
    cm = make_array(numClusters,numClusters,/LONG)
    size_out = size(predict)
    n_sample = max(size_out) 
    n=0UL
    
    ;Le righe rappresentano gli elementi predict
    ;Le colonne quelli di riferimento 
    
    while n lt n_sample DO BEGIN
    
    predict_index = predict[n] - 1
    reference_index  = reference[n] - 1
    
    cm[reference_index,predict_index] = cm[reference_index,predict_index]  + 1
    n = n + 1
    endwhile
    
    return , cm

end

function accuracy_index,  predict, reference , numClusters

;Ritorna una struttra dove i nomi delle variabili sono:
; -user's accuracies = user
; -producer's accuracies = producer
; -confusion matrix = confusion_matrix
; -khat indice = khat
 

;producer’s accuracies result from dividing the number of correctly classified pixels in each category 
;(on the major diagonal) by the num- ber of test set pixels used for that category (the column total). 

;User’s accuracies are computed by dividing the number of correctly classified 
;pixels in each category by the total number of pixels that were classified in that category (the row total).

confusion_matrix = confusion_matrix(predict,reference,numClusters)

user_accuracy = make_array(numclusters,/FLOAT)
producer_accuracy=  make_array(numclusters,/FLOAT)

sum_d_elem = 0.0 ;KHAT
sum_r_c = 0.0 ;KHAT
N = float(total(confusion_matrix))

FOR k = 0, numClusters - 1 DO BEGIN
  
  cl_sum = float(total(confusion_matrix[k,*]))
  rw_sum =  float(total(confusion_matrix[*,k]))
  d_elem = float(confusion_matrix[k,k])
  
  sum_r_c = sum_r_c + (cl_sum*rw_sum) ; KHAT
  sum_d_elem =  sum_d_elem + d_elem ;KHAT
  
  user_accuracy[k] = d_elem / cl_sum 
  producer_accuracy[k] = d_elem / rw_sum
  
ENDFOR

;KHAT refence on page 579

khat = (N*sum_d_elem - sum_r_c) / (N^2 - sum_r_c)

accuracy_struct = CREATE_STRUCT('confusion_matrix',confusion_matrix,'user',user_accuracy,'producer',producer_accuracy,'khat',khat)

return, accuracy_struct


end