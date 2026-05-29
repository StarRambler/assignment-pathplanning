function [Populations,BestPath,Curve]=AHA(SearchAgents,Populations,Max_iter,Info,seg_flag)
    VisitTable=zeros(SearchAgents) ;
    VisitTable(logical(eye(SearchAgents)))=NaN;

    numofUAV=size(Populations,1);
    BestPath=cell(1,numofUAV);
    Curve=cell(numofUAV,1);
    
    for i=1:numofUAV
        Curve{i}=zeros(1,Max_iter);
    end
    %% main loop
    for t=1:Max_iter
        newPopulations=Populations;
        for num=1:numofUAV
            startPos=Info.start(:,num);
            goalPos=Info.aim(:,num);
            DirectVector=zeros(SearchAgents,Populations{num}.dimension);% Direction vector/matrix
            
            for i=1:SearchAgents
                r=rand;
                if r<1/3     % Diagonal flight
                    RandDim=randperm(Populations{num}.dimension);
                    if Populations{num}.dimension>=1.5
                        RandNum=ceil(rand*(Populations{num}.dimension-2)+1);
                    else
                        RandNum=ceil(rand*(Populations{num}.dimension-1)+1);
                    end
                    DirectVector(i,RandDim(1:RandNum))=1;
                else
                    if r>2/3  % Omnidirectional flight
                        DirectVector(i,:)=1;
                    else  % Axial flight
                        RandNum=ceil(rand*Populations{num}.dimension);
                        DirectVector(i,RandNum)=1;
                    end
                end
    
                if rand<0.5   % Guided foraging
                    [MaxUnvisitedTime,TargetFoodIndex]=max(VisitTable(i,:));
                    MUT_Index=find(VisitTable(i,:)==MaxUnvisitedTime);
                    if length(MUT_Index)>1
                        [~,Ind]= min(newPopulations{num}.fitness(MUT_Index));
                        TargetFoodIndex=MUT_Index(Ind);
                    end
    
                    newPopulations{num}.Pos(i,:)=Populations{num}.Pos(TargetFoodIndex,:)+randn*DirectVector(i,:).*...
                        (Populations{num}.Pos(i,:)-Populations{num}.Pos(TargetFoodIndex,:));
                    newPopulations{num}.Pos(i,:)=SpaceBound(newPopulations{num}.Pos(i,:),newPopulations{num}.upperbound,newPopulations{num}.lowerbound);
                    
                    newPopulations{num}.Path{i} = updatePath(newPopulations{num}.Pos(i,:),Populations{num}.dimension,startPos,goalPos,newPopulations{num}.a,newPopulations{num}.b,newPopulations{num}.d,newPopulations{num}.type);
                    newPopulations{num}.fitness(i)=calFitness(newPopulations{num}.Path{i},newPopulations,num,Info,seg_flag);
                    if newPopulations{num}.fitness(i)<Populations{num}.fitness(i)
                        Populations{num}.fitness(i)=newPopulations{num}.fitness(i);
                        Populations{num}.Pos(i,:)=newPopulations{num}.Pos(i,:);
                        Populations{num}.Path(i,:)=newPopulations{num}.Path(i,:);
                        
                        VisitTable(i,:)=VisitTable(i,:)+1;
                        VisitTable(i,TargetFoodIndex)=0;
                        VisitTable(:,i)=max(VisitTable,[],2)+1;
                        VisitTable(i,i)=NaN;
                    else
                        VisitTable(i,:)=VisitTable(i,:)+1;
                        VisitTable(i,TargetFoodIndex)=0;
                    end
                else    % Territorial foraging
                    newPopulations{num}.Pos(i,:)= Populations{num}.Pos(i,:)+randn*DirectVector(i,:).*Populations{num}.Pos(i,:);
                    newPopulations{num}.Pos(i,:)=SpaceBound(newPopulations{num}.Pos(i,:),newPopulations{num}.upperbound,newPopulations{num}.lowerbound);
                    
                    newPopulations{num}.Path{i} = updatePath(newPopulations{num}.Pos(i,:),Populations{num}.dimension,startPos,goalPos,newPopulations{num}.a,newPopulations{num}.b,newPopulations{num}.d,newPopulations{num}.type);
                    newPopulations{num}.fitness(i)=calFitness(newPopulations{num}.Path{i},newPopulations,num,Info,seg_flag);
                    if newPopulations{num}.fitness(i)<Populations{num}.fitness(i)
                        Populations{num}.fitness(i)=newPopulations{num}.fitness(i);
                        Populations{num}.Pos(i,:)=newPopulations{num}.Pos(i,:);
                        Populations{num}.Path(i,:)=newPopulations{num}.Path(i,:);

                        VisitTable(i,:)=VisitTable(i,:)+1;
                        VisitTable(:,i)=max(VisitTable,[],2)+1;
                        VisitTable(i,i)=NaN;
                    else
                        VisitTable(i,:)=VisitTable(i,:)+1;
                    end
                end
            end
    
            if mod(t,2*SearchAgents)==0 % Migration foraging
                [~, MigrationIndex]=max(Populations{num}.fitness);
                Populations{num}.Pos(MigrationIndex,:) =rand(1,Populations{num}.dimension).*(Populations{num}.upperbound-Populations{num}.lowerbound)+Populations{num}.lowerbound;
                
                Populations{num}.Path{MigrationIndex} = updatePath(Populations{num}.Pos(MigrationIndex,:),Populations{num}.dimension,startPos,goalPos,Populations{num}.a,Populations{num}.b,Populations{num}.d,Populations{num}.type);
                Populations{num}.fitness(MigrationIndex)=calFitness(Populations{num}.Path{MigrationIndex},Populations,num,Info,seg_flag);
                
                VisitTable(MigrationIndex,:)=VisitTable(MigrationIndex,:)+1;
                VisitTable(:,MigrationIndex)=max(VisitTable,[],2)+1;
                VisitTable(MigrationIndex,MigrationIndex)=NaN;            
            end
        end
        for num=1:numofUAV
            for i=1:SearchAgents
                if Populations{num}.fitness(i)<Populations{num}.fbest
                    Populations{num}.fbest=Populations{num}.fitness(i);
                    Populations{num}.Xbest=Populations{num}.Pos(i,:);
                    Populations{num}.BestPath=Populations{num}.Path{i};
                end
            end
        end

        for num=1:numofUAV
            Curve{num}(t)=Populations{num}.fbest;
            BestPath{num}=Populations{num}.BestPath;
        end
        if mod(t,50)==0
            disp(strcat('第',num2str(t),'代的第一架：',num2str(Populations{1}.fbest),' 第2架：',num2str(Populations{2}.fbest)));
        end
    end
        
end