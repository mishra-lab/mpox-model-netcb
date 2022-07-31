library('reshape2')

# TODO: negative indices instead of setiff, faster ?

epi.t = function(t0=1,tf=180){
  t = seq(t0,tf)
}

epi.init.state = function(P){ # "X"
  i = seqn(P$N) # node indices
  I0 = sample.strat(i,P$N.I0.city, 
    strat   = P$G$attr$i$city,
    weights = P$G$attr$i$par.p6m)
  X = list()
  X$S = setdiff(i,I0) # i of susceptible
  X$E = numeric()     # i of exposed
  X$I = I0            # i of infected
  X$R = numeric()     # i of recovered
  X$V1 = numeric()    # i of vaccinated 1 dose
  X$V2 = numeric()    # i of vaccinated 2 dose
  return(X)
}

epi.mat.init = function(P,t){
  # large, complete representation: t (rows) x individuals (cols)
  M = array(character(0),dim=c(len(t),P$N),dimnames=list('t'=t,'i'=seqn(P$N)))
}

epi.mat.update = function(M,X,tj){
  # update M with current state
  M[tj,X$S]  = 'S'
  M[tj,X$E]  = 'E'
  M[tj,X$I]  = 'I'
  M[tj,X$R]  = 'R'
  M[tj,X$V1] = 'V1'
  M[tj,X$V2] = 'V2'
  return(M)
}

epi.do.vaccinate = function(P,X,tj){
  # get i of newly vaccinated
  Vj = list(numeric(0),numeric(0)) # dose 1, dose 2
  for (A in P$vax.args.phase){ # for each vaccination phase
    if ((tj > A$t0) & (tj <= A$t0 + A$dur)){ # is t during phase?
      N.city.day = (A$N / A$dur) * A$w.city # N vaccinated daily by city
      i = switch(A$dose,'1'=X$S,'2'=X$V1) # dose -> sampling from S or V1
      weights = switch(is.null(A$w.attr),T=NULL,F=P$G$attr$i[[A$w.attr]][i])
      # TODO: check empty args or something (rare error)
      Vj.phase = sample.strat(i,N.city.day, # sample by city, maybe with weights
        strat = P$G$attr$i$city[i],
        weights = weights)
      Vj[[A$dose]] = c(Vj[[A$dose]],Vj.phase) # append vax from this phase 
    }
  }
  Vj = lapply(Vj,unique) # remove any duplicates
}

epi.do.breakthrough = function(P,X){
  # get i of vaccinated who could experience breakthrough - TODO: can this be done (faster) via p?
  VSj = c(sample.i(X$V1,1-P$vax.eff.dose[1]),sample.i(X$V2,1-P$vax.eff.dose[2]))
}

epi.do.expose = function(P,X,Sj){
  # get i of newly infected
  Ej = sample.i(unlist(adjacent.i(P$G,X$I)),P$beta/P$net.dur)
  Ej = unique(intersect(Ej,Sj)) # unique exposed who are susceptible
}

epi.do.infectious = function(P,X){
  # get i of infectious
  Ij = sample.i(X$E,1/P$dur.exp)
}

epi.do.recovery = function(P,X){
  # get i of recovered
  Rj = sample.i(X$I,1/P$dur.inf)
}

epi.run = function(P,t){
  # run the epidemic
  set.seed(P$seed)
  X = epi.init.state(P)
  M = epi.mat.init(P,t)
  for (tj in t){
    M = epi.mat.update(M,X,tj) # log state
    # computing transitions
    Vj = epi.do.vaccinate(P,X,tj) # TODO: PEP
    Sj = c(X$S,epi.do.breakthrough(P,X))
    Ej = epi.do.expose(P,X,Sj)
    Ij = epi.do.infectious(P,X)
    Rj = epi.do.recovery(P,X)
    # applying transitions
    X$R  = c(X$R,Rj)                              # append new recovered
    X$I  = setdiff(c(X$I,Ij),Rj)                  # append new infectious & remove recovered
    X$E  = setdiff(c(X$E,Ej),Ij)                  # append new exposed & remove infectious
    X$V1 = setdiff(c(X$V1,Vj[[1]]),c(Ej,Vj[[2]])) # append new dose-1 & remove exposed, dose-2
    X$V2 = setdiff(c(X$V2,Vj[[2]]),Ej)            # append new dose-2 & remove exposed
    X$S  = setdiff(X$S,c(Ej,Vj[[1]]))             # remove exposed, dose-1
    if (.debug && sum(sapply(X,len)) != P$N){ stop('len(X) != P$N') }
  }
  return(M)
}

epi.run.s = function(P.s,t,results=TRUE,parallel=TRUE){
  # run for multiple seeds, and usually compute the results immediately too
  if (parallel){ lapply.fun = par.lapply } else { lapply.fun = lapply }
  if (results){
    lapply.fun(P.s,function(P){ epi.results(P,t,epi.run(P,t)) })
  } else {
    lapply.fun(P.s,function(P){ epi.run(P,t) })
  }
}

epi.results = function(P,t,M){
  # collect some results (don't include M, which is large)
  R = list()
  P$G = epi.net.attrs(P$G,M)
  R$P = P
  R$t = t
  R$out = epi.output(P,t,M)
  return(R)
}

epi.net.attrs = function(G,M){
  # add some attributes to G after running the model
  G$attr$i$inf.src = as.character(factor(M[1,]=='I',labels=c('Local','Import')))
  G$attr$i$health  = M[length(t),]
  return(G)
}

epi.output = function(P,t,M){
  # sum up the numbers of people in each state over time
  # yields a more efficient representation of M, but loses information
  city = P$G$attr$i$city
  out = data.frame('t'=t)
  for (h in c('S','E','I','R','V1','V2')){
    out[[join.str(h,'all')]] = rowSums(M==h)
    for (y in P$lab.city){
      out[[join.str(h,y)]] = rowSums(M[,city==y]==h)
    }
  }
  return(out)
}

epi.output.melt = function(out,P){
  # melt the data in out (usually for plotting)
  N.t = nrow(out)
  out.long = melt(out,id.vars='t')
  out.long = rename.cols(out.long,value='N')
  out.long = split.col(out.long,'variable',c('health','city'),del=TRUE)
  out.long$health = as.character(out.long$health)
  out.long$city   = as.character(out.long$city)
  out.long$seed   = P$seed
  N.city = rep(c(P$N,P$N.city),each=N.t,times=6) # NOTE: 6 from SEIRVV
  out.long$n.city = out.long$N / N.city # per-city prevalence
  return(out.long)
}

epi.output.melt.s = function(R.s,P.s){
  # apply epi.output.melt to a list of R.s -- e.g. from epi.run.s
  out.long.s = kw.call(rbind,lapply(P.s,function(P){
    out.long = epi.output.melt(R.s[[P$seed]]$out,P)
  }))
}