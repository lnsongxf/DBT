function [coh,csp,w,dbs,trf] =dbtcoh(x,y,varargin)


% Simple function to compute coherence values with dbt transforms.

% ----------- SVN REVISION INFO ------------------
% $URL$
% $Revision$
% $Date$
% $Author$
% ------------------------------------------------

i = 1;
dbtargs = {};
keep_time=[];
while i < length(varargin)
    
   switch varargin{i}
       
       case 'keep time'
           keep_time = varargin{i+1};
           i = i+1;
       otherwise
           dbtargs = [dbtargs,varargin(i:i+1)];
           i=i+1;
   end
   
   i=i+1;
end

if ~isa(x,'dbt')
 
    nx = size(x,2);    
else
    dbx = x;
    nx = size(dbx.blrep,3);
end

 dby = [];
if isscalar(y) && ~isa(y,'dbt')
    dbtargs = [{y},dbtargs];
    y=[];
    ny = nx;
elseif ~isempty(y) 
    if ~isa(y,'dbt')
        dby = dbt(y,dbtargs{:});
        ny = size(y,2);
    else
        dby = y;
        ny = size(dby.blrep,3);
    end
else
    ny = nx;    
end

if ~isa(x,'dbt')
    dbx = dbt(x,dbtargs{:});
end

if isempty(keep_time)
    keepT = true(size(dbx.time));
else
    keepT = resampi(keep_time,dbtargs{1},dbx.sampling_rate,'linear')>.5;
end

w = dbx.frequency;
csp = zeros(nx,ny,length(w));
coh = csp;
if nargout > 4
    trf = csp;
end
for i = 1:length(dbx.frequency)
        
        blx = squeeze(dbx.blrep(keepT,i,:));
        if isempty(y)
            bly = blx;
        else
            bly = squeeze(dby.blrep(keepT,i,:));
        end
        csp(:,:,i) = blx'*bly;
        if isempty(y)
             coh(:,:,i) = diag(diag(csp(:,:,i).^-.5))*csp(:,:,i)*diag(diag(csp(:,:,i)).^-.5);
        else          
           coh(:,:,i) = diag(sum(abs(blx).^2).^-.5)*csp(:,:,i)*diag(sum(abs(bly).^2).^-.5);
        end
        
    if nargout > 4
           trf(:,:,i) = diag(sum(abs(blx).^2))\(blx'*bly);
          
    end
end
    
if nargout > 3
    if isequal(x,y)
        dbs = dbx;
    else
        dbs = [dbx,dby];
    end
end



