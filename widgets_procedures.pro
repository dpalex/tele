pro classification_widgets
  ;La procedura visualizza vari widgets per la lettura dell'immagine 
  ;e il settaggio dell'algoritmo k-means
  
  ;seleziono l'immagine e leggo info d'interesse come nome,map_info,ns,nl,nb
  ENVI_SELECT,title='Image input file', fid = fid, pos = pos, dims = dims
  if (fid[0] eq -1) then return
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=nb, fname=fname
  
  map_info = ENVI_GET_MAP_INFO(FID=fid)
  
  ;ricevo l'informazione spaziale per ogni banda e compongo la matrice 3d
  data=make_array(ns,nl,nb)  
  for i=0,nb-1 do begin
    data[*,*,i] = Envi_get_data(fid = fid, dims = dims,pos=pos[i])
  endfor
  
  ;visualizzazione widget per configurazione kmeans
  base = widget_auto_base(title = 'Custom implementation K-Means')
  wl = widget_slabel(base, prompt = 'Load file and set all K-means parameters')
  file = widget_base(base, /row, /frame)
  sb = widget_base(base, /row, /frame)
  threshold = widget_param(sb, prompt = 'Threshold', dt = 5, default=0.1,uvalue = 'value_th', /auto) 
  num_classes = widget_param(sb, prompt = 'Num Classes', dt = 2,default=1, uvalue = 'value_k', /auto) 
  max_iter = widget_param(sb, prompt = 'Max Iteration', dt = 2,default=10, uvalue = 'value_max_iter', /auto) 
  pca_tab = widget_base(base, /row, /frame)
  pca = widget_menu(pca_tab, list=['Use PCA'], uvalue='pca', /auto)
  threshold_pca = widget_param(pca_tab, prompt = 'Threshold PCA', dt = 5,default=0.9, uvalue = 'value_th_pca', /auto) 
  sb = widget_base(base, /row, /frame)
  wf = widget_outfm(sb, uvalue = 'outf', /auto)
  result = auto_wid_mng(base)
  
  ; Se result.accept = 1 -> premuto tasto OK (ditruggi e continua)
  ; altrimenti result.accept = 0 -> premuto tasto CANCEL (ditruggi e ritorna).
  if (result.accept eq 0) then return
  ;prelevo i parametri di interesse
  if (result.accept eq 1) then begin
     file_path = fname
     threshold = result.value_th
     k = result.value_k
     max_iter = result.value_max_iter
     pca=result.pca
     threshold_pca = result.value_th_pca
     pca_name=''
     if(pca) then pca_name='pca'
     
     ;applico k-means
     out=myKmeans(data[*,*,*],k,threshold,max_iter,pca,threshold_pca)
     
     ;slavo in memoria
     if ((result.outf.in_memory) eq 1) then begin
         save_as_ENVI_CLASSIFICATION, out, k,'',pca_name,map_info,1
     ;salvo su file hdr
     endif else begin
         path_to_save= string(result.outf.name)
         save_as_ENVI_CLASSIFICATION, out, k,path_to_save,pca_name,map_info,0
     endelse
  endif    
end

pro post_classification_widgets
  ;procedura che mostra i widgets per la post-classificazione
  
  ;seleziono il file di classificazione
  envi_select, title='Classification input file', fid=fid, pos=pos
  envi_file_query, fid, data_type=data_type,dims=dims, ns=ns, nl=nl, nb=nb, interleave=interleave,fname=fname
  
  ;ricevo il contenuto spaziale del ROI
  reference=envi_get_data(fid=fid,dims=dims,pos=pos)

  ;controllo le regioni associate
  roi_ids = envi_get_roi_ids(fid=fid, roi_names=roi_names)
  if (roi_ids[0] eq -1) then begin
    print, 'No regions associeated with the selected file'
    return
  endif
  
  ;widget per la selezione delle rois
  base = widget_auto_base(title='ROI Selection')
  wm = widget_multi(base, list=roi_names, uvalue='list', /auto)
  result = auto_wid_mng(base)
  
  ;determino i puntatori da utilizzare per ricevere nomi e id delle roi
  ptr = where(result.list eq 1, count)
  regionNames=roi_names[ptr]
  roi_ids=roi_ids[ptr]
  
  ;widget per associare roi a classi
  regionNames=regionNames+' --> Class: '
  base = widget_auto_base(title='Associate ROI region to class')
  sz=size(regionNames)
  vals=indgen(sz[3])+1
  we = widget_edit(base, uvalue='edit', list=regionNames,dt=1,vals=vals, /auto)
  result = auto_wid_mng(base)
  if (result.accept eq 0) then return
  associatedClass = result.edit
  
    
  ;init array per il risultato della classificazione
  predict = make_array(ns,nl,type=byte)
  ;riempio la matrice 
  for i=0,n_elements(regionNames)-1 do begin
    roi_addr = envi_get_roi(roi_ids[i]) 
    predict[roi_addr]= associatedClass[i]
  endfor
  
  sizeRegion = size(regionNames)
  numClasses = sizeRegion[3]
  
  ;calcolo indici di qualita
  res=accuracy_index(predict,reference,numClasses)
  user_acc= res.user*100
  producer_acc= res.producer*100
  khat = res.khat

  ;mostro gli indici nel widget
  base = widget_base(title='Class Confusion Matrix')
  kc = string('     Kappa Coefficient =')+ string(khat)
  lbl =string('     Class        Prod. Acc. %        User Acc')
  delim =string('===========================')
  listValue = make_array(numClasses+4,/STRING)
  listValue[0] = kc
  listValue[1] = delim
  listValue[2] = lbl
  listValue[3] = delim
  
  for i=0,numClasses-1 do listValue[i+4]=  string(i+1)+'Class'+ ':   ' + string(user_acc[i]) + '   ' + string(producer_acc[i])
  
  ws = widget_slabel(base, prompt=listValue,xsize='150',ysize='50')
  widget_control, base, /realize
end
