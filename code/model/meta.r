M = list()
M$health = list()
M$health$title = 'State'
M$health$name = c('S','E','I','H','R','V1','V2')
M$health$label = c(
  'S'  = 'Susceptible',
  'E'  = 'Exposed',
  'I'  = 'Infectious',
  'H'  = 'Isolating',
  'R'  = 'Recovered',
  'V1' = 'Vax 1 Dose',
  'V2' = 'Vax 2 Dose')
M$health$color = c(
  'S'  = '#ffcc00',
  'E'  = '#ff7700',
  'I'  = '#ff0066',
  'H'  = '#cc00cc',
  'R'  = '#0099ff',
  'V1' = '#33cc99',
  'V2' = '#009999')
M$health$fill = M$health$color
M$main = list()
M$main$title = 'Main\nPartner'
M$main$name = c('excl','open','noma')
M$main$label = c(
  'excl' = 'Excl',
  'open' = 'Open',
  'noma' = 'None')
M$main$color = c(
  'excl' = '#006699',
  'open' = '#0099cc',
  'noma' = '#ff9933')
M$main$fill = M$main$color
M$main.any = M$main
M$main.any$title = 'Main\nPartner\nP6M'
M$main.now = M$main
M$main.now$title = 'Main\nPartner\nCurrent'
M$inf.src = list()
M$inf.src$title = 'Infection\nSource'
M$inf.src$name = c('loc','imp')
M$inf.src$label = c(
  'loc' = 'Local',
  'imp' = 'Import')
M$inf.src$color = c(
  'loc' = '#000000',
  'imp' = '#ff0066')
M$inf.src$fill = M$inf.src$color
M$inf.src$shape = c(
  'loc' = 21,
  'imp' = 23)
M$active = list()
M$active$title = 'Active'
M$active$label = c('No','Yes')
M$active$linetype = c(0,1)
