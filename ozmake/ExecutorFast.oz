%% Here, we by-pass the creation of a subprocess for invoking the
%% Oz compiler.  Instead, we invoke it directly in the current process,
%% using the Compiler module.
functor
export
   'class' : ExecutorFast
import
   Compiler
   Windows at 'Windows.ozf'
   Path    at 'Path.ozf'
define
   class ExecutorFast
      meth exec_fast_ozc(FromFile ToFile
                         debug      : Debug      <= false
                         executable : Executable <= false
                         gumpdir    : Gumpdir    <= unit)
         BatchCompiler = {New Compiler.engine init()}
         UI = {New Compiler.interface init(BatchCompiler auto)}
      in
         {BatchCompiler enqueue(setSwitch(showdeclares false))}
         {BatchCompiler enqueue(setSwitch(threadedqueries false))}
         if Gumpdir==unit then D={Path.dirname ToFile} in
            if D\=nil then
               {BatchCompiler enqueue(setGumpDirectory({Path.dirname ToFile}))}
            end
         else
            {BatchCompiler enqueue(setGumpDirectory(Gumpdir))}
         end
         if Debug then
            {BatchCompiler enqueue(setSwitch(controlflowinfo true))}
            {BatchCompiler enqueue(setSwitch(staticvarnames true))}
         end
         {BatchCompiler enqueue(setSwitch(expression true))}
         {BatchCompiler enqueue(setSwitch(feedtoemulator true))}
         local R in
            {BatchCompiler enqueue(feedFile(FromFile return(result:?R)))}
            {UI sync()}
            if {UI hasErrors($)} then raise ozmake(build:fast) end end
            if Executable then
               {self exec_save_with_header(R ToFile Windows.execHeader 9)}
               {self exec_mkexec(ToFile)}
            else
               {self exec_save_with_header(R ToFile '' 9)}
            end
         end
      end
   end
end
