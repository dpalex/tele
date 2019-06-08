function compute_covariance_matrix, features_vector
      
      covariance_matrix =  CORRELATE(transpose(features_vector),/COVARIANCE)
      
      return, covariance_matrix
      
end


function mypca, features_vector , threshold

      ;Reference : https://sebastianraschka.com/Articles/2014_pca_step_by_step.html#drop_labels
      ;https://towardsdatascience.com/principal-component-analysis-your-tutorial-and-code-9719d3d3f376
      ;https://github.com/wlandsman/IDLAstro/blob/master/pro/pca.pro
      
      ;Calcolo la matrice delle covarianze
      cm = compute_covariance_matrix(features_vector)
      ;Calcolo gli autovalori e gli autovettori
      eigenvalue = eigenql(cm, EIGENVECTORS=eigenvector)
      
      ;Calcolo gli indici degli autovalori dal più grande al più piccolo
      max_indices = REVERSE(SORT(eigenvalue))
      ;Riordino gli autovettori in funzione degli autovalori
      
      sorted_eigenvalue =  eigenvalue[max_indices]
      sorted_eigenvector = eigenvector[*,max_indices]
           
       sum_eigenvalue = total(eigenvalue)

       ;Ora scelgo gli autovettori corrispondenti agli autovalori
       ; che racchiudono una percentuale >= della somma 
       ;totale di tutti gli autovalori
       ;La percentuale è definita da threshold
       
       variance_threshold = float(sum_eigenvalue*threshold)
       
       actual_variance=0.0
       i = 0
       
       WHILE actual_variance lt variance_threshold DO BEGIN
       
       actual_variance = actual_variance + sorted_eigenvalue[i]
       i = i + 1
       
       ENDWHILE
       
       
       ;Proiettiamo le componenti nel nuovo spazio
       ; tramite  y = transp(W) x X
       ; Dote W è il vettore degli autovettori per colonna (projection matrix) ed X l'intero dataset
       

       IF i ne 0 THEN BEGIN
       
       projection_matrix = sorted_eigenvector[*,0:i-1]
            
       pca_data = double(projection_matrix) ## double(features_vector)
       
       print, "Dimensionalità totale: "
       print, i
              
       return, double(pca_data)
        
       ENDIF ELSE BEGIN
       
       return , double(features_vector)
               
       ENDELSE
       
 
end