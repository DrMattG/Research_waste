library(DiagrammeR)
grViz("digraph flowchart {
      rankdir=LR
      # node definitions with substituted label text
      node [fontname = Helvetica, shape = rectangle]        
      tab1 [label = '@@1']
      tab2 [label = '@@2']
      tab3 [label = '@@3']
      tab4 [label = '@@4']
      tab5 [label = '@@5']

      # edge definitions with the node IDs
      tab1 -> tab2 -> tab3 -> tab4;
      tab1->tab5;
      tab2->tab5;
      tab3->tab5;
      tab4->tab5;
      
      }

      [1]: 'Questions relevant to stakeholders'
      [2]: 'Appropriate design & methods'
      [3]: 'Accessible full publication'
      [4]: 'Unbiased reporting'
      [5]: 'Research waste'
      ")


grViz("
digraph boxes_and_circles {

  # a 'graph' statement
  graph [overlap = true, fontsize = 10]

  # several 'node' statements
  node [shape = box,
        fontname = Helvetica]
      tab1 [label = '@@1']
      tab2 [label = '@@2']
      tab3 [label = '@@3']
      tab4 [label = '@@4']
      tab5 [label = '@@5']
  node [shape = circle,
        fixedsize = true,
        width = 2] // sets as circles
    tab6 [label = '@@6']
    node [shape = diamond, width=3.7]
    tab7 [label = '@@7']
  # several 'edge' statements
 tab1->tab2->tab3->tab4
 tab1->tab5
  tab2->tab5
   tab3->tab5
    tab4->tab5
    tab4->tab6 
    tab6->tab7 [style=dotted]
          tab6->tab5 [style=dashed]
    tab7->tab1 [style=dotted]
        tab7->tab2 [style=dotted]
    
    
}
      [1]: 'Questions relevant to stakeholders'
      [2]: 'Appropriate design & methods'
      [3]: 'Accessible full publication'
      [4]: 'Unbiased reporting'
      [5]: 'Research waste'
      [6]: 'Evidence synthesis'
      [7]: 'Cummulative meta-analysis'
")
