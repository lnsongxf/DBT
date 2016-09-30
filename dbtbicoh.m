function [BICOH,w,bspect,NRM] = dbtbicoh(x,fs,bw,varargin)

% Computes bicoherence with DBT.
%
% This script is under development and is not stable. Do not use it unless
% you know what you're doing.

% ----------- SVN REVISION INFO ------------------
% $URL$
% $Revision$
% $Date$
% $Author$
% ------------------------------------------------

% C. Kovach 2016

warning('This script is under development and is not stable. Do not use it unless you know what you''re doing')

if nargin < 3
    bw = 1;    
end
upsampfx = 1;
rotation = 'ww';

type = 'fcov';
switch lower(type)
    case 'fcov'
        %%
        upsamptx = round(min(250,fs)/(2*bw));
        %%% Compute DBT
        dbx = dbt(x,fs,bw,'upsampleTx',upsamptx-1,'upsampleFx',upsampfx,'remodphase',true);
       %%% Anti-aliasing filter and decimation
        getfreq = dbx.sampling_rate/2;
        nadj = sum(dbx.time<=(length(x)-1)./fs);
        %%% Get lowpass and hilbert filtered data
        fxrs = fft(dbx.signal(dbx.frequency < getfreq,false));
        
        %%% Resample to match dbt sampling rate as nearly as possible
        fxrs(nadj+1:end)=[];
        xrs = real(ifft(fxrs));
        
        
        % decim = fs./dbx.sampling_rate;
        % xrs = x(round(decim/2):decim:end,:);
        
        %%% Weight with original signal 
        blrep = dbx.blrep(1:length(xrs),dbx.frequency<getfreq);
        w = dbx.frequency(dbx.frequency<getfreq);
        sz = size(blrep);
        sz(end+1:3)=1;
        blrep = reshape(blrep,[sz(1) sz(2)*sz(3)]);
        Wblrep = reshape(repmat(permute(xrs,[1 3 2]),1,length(w)),[sz(1) sz(2)*sz(3)]).*blrep;
        %%% Estimate bispectrum using the frequency-domain covariance
        %%% method (Kovach 2016)
        bspect = conj(blrep)'*Wblrep;
              [W1,W2] = ndgrid(1:length(w),1:length(w));
                W3 = W1+W2-1;
                inds = W3<=size(blrep,2);
         normalization ='std';
        switch normalization
%             case 'sig'
%                  %%% Signal to generate normalizing term of bicoherence
%                  dbxnrm = dbx;
%                 dbxnrm.blrep = dbxnrm.blrep;
%                 dbxnrm.remodphase=true;
%                 fnrmxrs = fft(dbxnrm.signal(dbx.frequency < getfreq,true));
%                 fnrmxrs(nadj+1:end)=[];
%                 nrmxrs = real(ifft(fnrmxrs));
%                 
%                 blrepnrm = dbxnrm.blrep;%.*dbxnrm.remodulator;
%                 blrepnrm = blrepnrm(1:length(nrmxrs),dbxnrm.frequency<getfreq);
%                 blrepnrm = reshape(blrepnrm,[sz(1) sz(2)*sz(3)]);
%                 Wblreprnm = reshape(repmat(permute(nrmxrs,[1 3 2]),1,length(w)),[sz(1) sz(2)*sz(3)]).*blrepnrm;
%                 %%% Estimate bispectrum using the frequency-domain covariance
%                 %%% method (Kovach 2016)
%                 NRM = conj(blrepnrm)'*Wblreprnm;
%               case 'cube'
%                 %%% Normalization with the root product of the sum of cubed energy
%                 %%% in each band        
%                 SC =sum(abs(blrep).^3);
%                  NRM = nan(size(bspect));
%                 NRM(inds) = (SC(W1(inds)).*SC(W2(inds)).*SC(W3(inds))).^(1/3);     
            case 'std'
                 SS = sum(abs(blrep).^2);
                 SSQ = (abs(blrep').^2*abs(blrep).^2);
                 NRM = nan(size(bspect));
                 NRM(inds) = sqrt(SSQ(inds).*SS(W3(inds))');
             case 'smstd'
                 SS = convn(sum(abs(blrep).^2),ones(1,2));
                 SSQ = (abs(blrep').^2*abs(blrep).^2);
                 NRM = nan(size(bspect));
                 NRM(inds) = sqrt(SSQ(inds).*SS(W3(inds))');
%             case 'band'
%                  dbp = dbt(abs(blrep).^2,dbx.sampling_rate,bw,'upsampleFx',upsampfx);
%                  MSS = squeeze(sum(abs(dbp.blrep(:,dbp.frequency<getfreq,:)).^2));
%                  XSS = sum(abs(blrep).^2);
%                  NRM = nan(size(bspect));
%                  NRM(inds) = sqrt(MSS(inds).*XSS(W3(inds))');
        end
%        Wnrm = reshape(repmat(permute(abs(xrs),[1 3 2]),1,length(w)),[sz(1) sz(2)*sz(3)]).*abs(blrep);
     
    case {'single','BBB','NNN'} 
        %% The standard approach
        
            
                  dbx = dbt(x,fs,bw,'upsampleFx',upsampfx*0);
  
                 
                 getfreq = 126;
                 getf = dbx.frequency<=getfreq & dbx.frequency>=0;
                 switch rotation
                     case 'ww'
                         
                         [W1,W2] = ndgrid(1:sum(getf));      
                         W3 = W1+W2-1;
                     case 'vv'
                         [V1,V2] = ndgrid(1:sum(getf));        
                        W1=(V1-V2)+1;
                        W2=(V1+V2)-1;
                        W3 = 2*V1-1;

                 end
                 %  inds = W3<=length(dbx.frequency);
                 inds = W1>0 & W2 <=length(dbx.frequency)& W3<=length(dbx.frequency);
                 w = dbx.frequency(getf);
                 blrep = dbx.blrep(:,dbx.frequency>=0);
                 cblrep = conj(dbx.blrep(:,dbx.frequency>=0));
                 bspect = nan(size(W1));
                 I1=W1;I2=W2;I3=W3;
                % I1=V1;I2=V2;I3=V3;
                 bspect(inds) = sum(blrep(:,I1(inds),:).*blrep(:,I2(inds),:).* cblrep(:,I3(inds),:));
                    
                 NRM = nan(size(I1));
                 NRM(inds) = sqrt(sum(abs(blrep(:,I1(inds),:).*blrep(:,I2(inds),:)).^2).* sum(abs(cblrep(:,I3(inds),:)).^2));
             
end
   BICOH = bspect./NRM;
                     