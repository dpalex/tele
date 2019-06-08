function myroi

envi_select, title='Input Filename of Image', fid=fid, pos=pos
envi_file_query, fid, data_type=data_type, ns=ns, nl=nl, nb=nb, interleave=interleave

roi_ids = envi_get_roi_ids(fid=fid, roi_names=roi_names)
if (roi_ids[0] eq -1) then begin
print, 'No regions associeated with the selected file'
return, 0
endif

;build a compound widget for selecting the desired ROIs
base = widget_auto_base(title='ROI Selection')
wm = widget_multi(base, list=roi_names, uvalue='list', /auto)
result = auto_wid_mng(base)

;count is an output of the ROI selection widget that is the number of ROIs selected
;ptr is equal to count for all all valid lists (lists with value of 1 rather than -1)
ptr = where(result.list eq 1, count)
regionNames=roi_names[ptr]
roi_ids=roi_ids[ptr]

;determine the total number of ROI points and make an array that is nb x number of points
tot_pnts=lonarr(count)

final_matrix = make_array(ns,nl,type=byte)

regionNames=regionNames+' --> Class: '
associatedClass = ENVI_WIDGET_EDIT_EX(regionNames)


  

for i=0,n_elements(regionNames)-1 do begin

roi_addr = envi_get_roi(roi_ids[i]) 
final_matrix[roi_addr]= associatedClass[i]

endfor

finalStruct = CREATE_STRUCT('roi_names',roi_names,'final_matrix',final_matrix)

return, finalStruct

end

function ENVI_WIDGET_EDIT_EX,list
  compile_opt IDL2
  base = widget_auto_base(title='Associate ROI region to class')
  sz=size(list)
  vals=indgen(sz[3])+1
  we = widget_edit(base, uvalue='edit', list=list,dt=1,vals=vals, /auto)
  result = auto_wid_mng(base)
  if (result.accept eq 0) then return,0
  return, result.edit
END