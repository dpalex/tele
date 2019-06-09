pro custom_menu_event, ev
  ;gestore eventi, controllo l'evento e associo la procedura di classificazione/post-classificazione
  widget_control, ev.id, get_uvalue = uvalue
  choice = uvalue
  if (choice eq 'kmeans') then classification_widgets
  if (choice eq 'confusion_matrix') then post_classification_widgets
end