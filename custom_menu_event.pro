pro custom_menu_event, ev
  widget_control, ev.id, get_uvalue = uvalue
  choice = uvalue
  
  ENVI_SELECT, fid = fid, pos = pos, dims = dims
  if (fid[0] eq -1) then return
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=nb, fname=fname
  map_info = ENVI_GET_MAP_INFO(FID=fid)
  data=make_array(ns,nl,nb)
  for i=0,nb-1 do begin
    data[*,*,i] = Envi_get_data(fid = fid, dims = dims,pos=pos[i])
  endfor
  
  if (choice eq 'kmeans') then begin
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
    if (result.accept eq 1) then begin
       file_path = fname
       threshold = result.value_th
       k = result.value_k
       max_iter = result.value_max_iter
       pca=result.pca
       threshold_pca = result.value_th_pca
       pca_name=''

       
       out=myKmeans(data[*,*,*],k,threshold,max_iter,pca,threshold_pca)
       if(pca) then pca_name='pca'
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;;;;;;;;;;       Salvataggio dei risultati
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        if ((result.outf.in_memory) eq 1) then begin
            save_as_ENVI_CLASSIFICATION, out, k,'',pca_name,map_info,1
            
        endif else begin
            ; result.outf.name contiene il percorso + il nome del file inserito dall'utente per il salvataggio 
            path_to_save= string(result.outf.name)
            save_as_ENVI_CLASSIFICATION, out, k,path_to_save,pca_name,map_info,0
        endelse
        endif
    
  endif
  
  
end