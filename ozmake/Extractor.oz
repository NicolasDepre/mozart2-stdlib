functor
export
   'class' : Extractor
import
   URL Resolve
   Utils at 'Utils.ozf'
   Path  at 'Path.ozf'
define
   class Extractor

      meth extract(writeMakefile:MAK<=true)
         %% when we install from a package file, we don't actually
         %% need to write the makefile because it is already read
         %% in memory when we read the package file: that's the
         %% reason for the MAK argument.
         REC = Extractor,Load({self get_package($)} $)
         DIR = {self get_extractdir($)}
      in
         %% a few sanity checks.  however, the main sanity checks
         %% will be done when reading in the makefile
         if {Not {IsRecord REC}} then
            raise ozmake(extract:badrecord(REC)) end
         end
         if {Not {HasFeature REC info}} then
            raise ozmake(extract:noinfo(REC)) end
         end
         if {Not {HasFeature REC data}} then
            raise ozmake(extract:nodata(REC)) end
         end
         if {Not {IsList REC.data}} then
            raise ozmake(extract:baddata(REC.data)) end
         end
         %% perform sanity checks on the data files to make sure that
         %% they have relative filenames, that their data is actually
         %% a virtual string
         for X in REC.data do
            case X of F#D then
               if {Not {IsVirtualString F}} then
                  raise ozmake(extract:filenotvs(F)) end
               elseif {Not {Path.isRelative F}} then
                  raise ozmake(extract:filenotrelative(F)) end
               elseif {Not {IsVirtualString D}} then
                  raise ozmake(extract:filedatanotvs(F D)) end
               end
            else raise ozmake(extract:baddatapair(X)) end end
         end
         %% write out the files
         for F#D in REC.data do
            {self exec_write_to_file(D {Path.resolve DIR F})}
         end
         if MAK then
            Extractor,WriteMakefile(DIR REC.info)
            {self set_submakefiles(unit)}
         end
         if {Not MAK} orelse {self get_justprint($)} then
            %% when installing from a package, we don't actually need to
            %% write the makefile and read it again.  Also, during a dry
            %% run, we won't do that anyway, but we don't want the errors
            %% that come from _not_ having a makefile.  Therefore, in
            %% both cases, we initialize the makefile info from the package
            %% record we just read, but we don't actually write out the
            %% makefile.
            {self makefile_from_record(REC.info fromPackage:true)}
            {self set_no_makefile(false)}
         end
      end

      meth WriteMakefile(DIR R)
         {self exec_write_to_file(
                  {Value.toVirtualString
                   {Record.subtract R submakefiles}
                   1000000 1000000}
                  {Path.resolve DIR "makefile.oz"})}
         for DD#RR in {Record.toListInd {CondSelect R submakefiles o}} do
            Extractor,WriteMakefile({Path.resolve DIR DD} RR)
         end
      end

      meth Load(PKG $)
         try
            if {Utils.isMogulID PKG} then
               %% if the package is given as a mogul id, then we
               %% download the appropriate file from the mogul
               %% archive
               Archive = {self get_archive($)}
               Filename = {Utils.mogulToPackagename PKG}
               Url = {URL.resolve {URL.toBase Archive} Filename}
               UrlStr = {URL.toString Url}
            in
               {self xtrace('downloading '#UrlStr)}
               {{Resolve.make 'ozmake'
                 init([Resolve.handler.default])}.load
                Url}
            else
               %% otherwise, we read it in the usual way, except that
               %% in order to minimize surprizes, we try the default
               %% methods first rather than risk getting something
               %% stale from some cache
               if {CondSelect {URL.make PKG} scheme unit}\=unit then
                  {self xtrace('downloading package '#PKG)}
               else
                  {self trace('reading package '#PKG)}
               end
               {{Resolve.make 'ozmake'
                 init(Resolve.handler.default|
                      {Resolve.pickle.getHandlers})}.load PKG}
            end
         catch _ then raise ozmake(extract:load(PKG)) end end
      end

   end
end
