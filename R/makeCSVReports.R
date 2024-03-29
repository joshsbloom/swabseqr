#curate preciseQ orders
getOrders=function(...){
    #sync samba share with local mirror
    system(paste0('rsync  -ahe --update ',  cfg$incomingOrders.dir, ' --delete ', cfg$localIncomingOrders.dir))
    
    #faster to iterate through local mirror version
    orders.files.short=list.files(cfg$localIncomingOrders.dir, pattern='csv', full.names=F, recursive=T)
    orders.files.full=list.files(cfg$localIncomingOrders.dir, pattern='csv', full.names=T, recursive=T)
    orders.files.entries=lapply(orders.files.full,readr::read_csv, col_types=readr::cols(.default='c'))
    names(orders.files.entries)=orders.files.short
    orders.files=data.table::rbindlist(orders.files.entries, idcol='orders_file')
    
    return(orders.files)
}

#get previous inconclusive samples 
getPrevResults=function(..., inconclusive_rate_for_failed_run=0.5) {
    run.samples=list.files(paste0(cfg$localMirrorSeq.run.dir), pattern='_report.csv', full.names=T, recursive=T)
    #new code added 07/27/21 to reduce lookup of previous samples to those run within the last two weeks 
    # note changed from 9 to 7 for working on non chs workstation, needs a variable here
    edates=base::as.Date(data.table::tstrsplit(data.table::tstrsplit(run.samples, '/')[[7]], '_')[[1]], '%y%m%d')
    #get previous runs within the last 2 weeks
    run.samples=run.samples[abs(edates-Sys.Date())<14]
    
    #08/22/21 fix issue with report auto type detection
    r.files.entries=lapply(run.samples,readr::read_csv, col_types="cccddcccccccccccccccclcdddddddddlcccccc")
                           #readr::cols())
    r.files=data.table::rbindlist(r.files.entries)
    #r.files=r.files[,-1]
    r.files=r.files %>% dplyr::distinct() # %>% filter(experiment!='experiment')

    experiment.inconclusive.rate=r.files %>% 
        dplyr::group_by(experimentName) %>% 
        dplyr::summarize(inconclusive_rate=sum(result=='Inconclusive')/dplyr::n())

    failed.experiments=experiment.inconclusive.rate$experimentName[experiment.inconclusive.rate$inconclusive_rate>inconclusive_rate_for_failed_run | grepl('^[A-Z]', experiment.inconclusive.rate$experimentName)]
    if(!identical(failed.experiments, character(0))){
        r.files=r.files[!(r.files$experimentName %in% failed.experiments),]
    }
    #prev.inconclusives=r.files %>% filter(SARS_COV_2_Detected=='Inconclusive')
    return(r.files)
#    return(prev.inconclusives)
}
 
getSeqStartTimes=function(...) {
        rTable = getRunTableStatus()

        runStartTime=list()
        for(rn in rTable$Name) {
            #print(rn)
             rparam.file=paste0(cfg$localMirrorSeq.run.dir, rn, '/RunParameters.xml')
             if(file.exists(rparam.file)){
             xmlinfo=XML::xmlToList(XML::xmlParse(rparam.file))
                if(is.null(xmlinfo$RunStartTimeStamp)) {
                    startmunge=xmlinfo$PreRunFolder
                    startmunge=gsub('.*\\\\', '', startmunge)
                    startmunge=gsub('^N.*_202', '202', startmunge)
                    startmunge=gsub('__', 'T', startmunge)
                    startmunge=gsub('_', ':', startmunge)
                    startmunge=paste0(startmunge, '.0000000-00:00')
                    runStartTime[[rn]]=startmunge
                }
                else {    runStartTime[[rn]]=xmlinfo$RunStartTimeStamp }
             }
        }
        #runStartTime=runStartTime %>% tibble::enframe("sequencingRunName", "sequencingRunStartTime") %>% 
        #                    tidyr::unnest(cols=c("sequencingRunName", "sequencingRunStartTime"))
        runStartTime=data.frame(sequencingRunName=names(runStartTime), sequencingRunStartTime=as.vector(do.call('c', runStartTime)), stringsAsFactors=F)
                        
        return(runStartTime)
    }

#engine to sync reports and track inconclusives 

#' Sync Reports to shared drive 
#'
#' If cfg environment variable is set, this function will generate csv reports and sync to the shared drive
#' @param syncToShared flag to sync results to sample tracking folder, set to F for debugging 
#'
#' @export
syncReports=function(..., syncToShared=T, writeCurrentResultsTable=F) {
    rTable = getRunTableStatus()
     
    dir.create(cfg$localMirrorSeq.dir)
    # sync remote/seq dir to local mirror
    system(paste0('rsync  -ahe --update ',  cfg$seq.dir, ' --delete ', cfg$localMirrorSeq.dir))

    seqStartTimes=getSeqStartTimes() 
    currResults=getPrevResults()
    

    for(r in 1:nrow(rTable)) {
        
        runName=rTable$Name[r] 
        #bcl.dir is different here
        bcl.dir=paste0(cfg$bcl.dir, runName, '/')
        odir=paste0(cfg$seq.run.dir, runName)
        if(rTable$Downloaded[r] & rTable$Bcl2fastq[r] & rTable$Demuxed[r] & rTable$Analyzed[r] & !rTable$Reported[r]){
            
            if(writeCurrentResultsTable) {
                currResults %>% utils::write.csv(paste0(cfg$remote.dir, 'completed/', Sys.Date(), '_current_results.csv'), row.names=F)
            }
                
            #added code to disable reporting for inconclusive runs 10/17/21
            technicalFail=F
           
            results=currResults %>% dplyr::filter(sequencingRunName==runName)
            if(nrow(results)==0 ){ technicalFail=T }
          
            if(!technicalFail){

            currRunStartTime=seqStartTimes$sequencingRunStartTime[seqStartTimes$sequencingRunName==runName]
           
            # get previous inconclusives 
            prevInconclusives=currResults %>% 
                dplyr::left_join(seqStartTimes, by='sequencingRunName') %>% 
                dplyr::filter(sequencingRunStartTime<currRunStartTime) %>% 
                dplyr::filter(result=='Inconclusive')%>%dplyr::select(Barcode) %>% 
                dplyr::distinct()
            
            #07/27/21 
            #barcodes of previous low positives 
            prevLowPos=currResults %>% 
                dplyr::left_join(seqStartTimes, by='sequencingRunName') %>% 
                dplyr::filter(sequencingRunStartTime<currRunStartTime) %>% 
                dplyr::filter(result=='Positive' & (S2_normalized_to_S2_spike>cfg$coreVars$Ratio & S2_normalized_to_S2_spike<0.5))%>%dplyr::select(Barcode) %>% 
                dplyr::distinct()
       
            #07/27/21
            results = results %>% dplyr::mutate(currLowPos=!(Barcode %in% prevLowPos$Barcode) & (S2_normalized_to_S2_spike>cfg$coreVars$Ratio & S2_normalized_to_S2_spike<0.5) )
            #added code to disable reporting for inconclusive runs 10/17/21
           
            # output the inconclusives that have only occurred once and should be rerun 
            # 07/27/21 or the current low positives 

                fo=paste0(odir,'/results/', rTable$Experiment[r],'_please_pull_inconclusives.csv')
                if(file.exists(fo)){file.remove(fo)}
                #07/27/21
                #dplyr::filter(result=='Inconclusive' | currLowPos) 
                results %>% dplyr::filter(result=='Inconclusive'| currLowPos ) %>% 
                            dplyr::filter(!(Barcode %in% prevInconclusives$Barcode)) %>%
                            dplyr::select("Barcode","result","S2_normalized_to_S2_spike", "Plate_384","Plate_96_BC","quadrant_96","Pos96","orders_file","Organization","Department","Population","Collection date+time") %>%
                            dplyr::arrange(Plate_384, quadrant_96, Pos96) %>%
                            utils::write.csv(fo, row.names=F)

                # output the positives for a run 
                fo=paste0(odir,'/results/', rTable$Experiment[r],'_positives.csv')
                if(file.exists(fo)){file.remove(fo)}
                
                #07/27/21
                # dplyr::filter(result=='Positive' & !currLowPos) 
                results %>% dplyr::filter(result=='Positive' & !currLowPos ) %>% 
                        dplyr::select("Barcode","result","S2_normalized_to_S2_spike","Plate_384","Plate_96_BC","quadrant_96","Pos96","orders_file","Organization","Department","Population","Collection date+time") %>%
                        dplyr::arrange(Plate_384, quadrant_96, Pos96) %>%
                        utils::write.csv(fo, row.names=F)

                # create output directory
                dir.create(paste0(odir,'/results/abbrev/'))

                # output information on positives/negatives for upload to preciseQ
                results.split=results%>% dplyr::select("Barcode","result","currLowPos", "orders_file","Organization","Department","Population","Collection date+time")
                #added 3/10/21 for new 
                results.split$status='Received'
                results.split = results.split %>% dplyr::relocate(status, .after=result)
                # ---
                results.split=split(results.split, results$Organization)
                for(n in names(results.split)){
                     #results that aren't inconclusive
                     fo=paste0(odir,'/results/abbrev/', rTable$Experiment[r],'_',n, '_results.csv')
                     if(file.exists(fo)){file.remove(fo)}
                     
                     #07/27/21
                     #dplyr::filter(result!='Inconclusive' & !currLowPos) 
                     results.split[[n]] %>% dplyr::filter(result!='Inconclusive' & !currLowPos ) %>% dplyr::select(-currLowPos) %>%
                         dplyr::arrange(orders_file, Barcode) %>% dplyr::distinct() %>% utils::write.csv(fo, row.names=F)
                    
                     #results that are inconclusive and were inconclusive for a previous run
                     fo=paste0(odir,'/results/abbrev/', rTable$Experiment[r],'_',n, '_inconclusives_results.csv')
                     if(file.exists(fo)){file.remove(fo)}
                   
                     #07/27/21
                     #dplyr::filter(Barcode %in% prevInconclusives$Barcode | Barcode %in% prevLowPos$Barcode  )
                     results.split[[n]] %>%  dplyr::filter(result=='Inconclusive') %>% dplyr::filter((Barcode %in% prevInconclusives$Barcode) | (Barcode %in% prevLowPos$Barcode) ) %>% dplyr::select(-currLowPos) %>%
                         dplyr::arrange(orders_file, Barcode) %>% dplyr::distinct() %>% utils::write.csv(fo, row.names=F)
               }   
            }
            rTable$Reported[r]=T  
            write_yaml_cfg(rTable,cfg)
            #sync results to swabseq sample tracking 
            if(syncToShared) {
            dir.create(paste0(cfg$tracking.dir, rTable$Experiment[r],'/results/'))
            dir.create(paste0(cfg$tracking.dir, rTable$Experiment[r],'/uploaded/'))
           # --delete 
            system(paste0('rsync  -avhe --update ',  odir,'/results/', ' --delete ', cfg$tracking.dir, rTable$Experiment[r],'/results/')) #cfg$localMirrorSeq.dir))
            }
           #
            curOrders=getOrders() %>% dplyr::filter(!grepl('\\/2020',orders_file))
            dplyr::anti_join(curOrders,currResults,by="Barcode")%>%
                dplyr::select("Barcode","orders_file","Organization","Department","Population","Collection date+time") %>%
                    utils::write.csv(paste0(cfg$remote.dir, 'missing/', Sys.Date(), '_orders_not_accessioned.csv'), row.names=F)
                
             #add code somewhere near here for tracking orders not accessioned 
    }

    }
}

