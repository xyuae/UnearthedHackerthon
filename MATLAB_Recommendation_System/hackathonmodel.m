clear;
%setting system parameters
s = 10; %number of possible inspection interval
M0 = {[0.95 0.05 0;   %deterioration model
    0 0.7591 0.2409;
    0 0 1],...
    [0.9 0.1 0;
    0 0.8 0.2;
    0 0 1]};
machineNum = size(M0,2); %number of machines
P = hackathontrans(M0,s); %P matrix
states = 3;  %number of states for one machine
stateNum = 3^machineNum*s; %number of states of the system
decisionNum = 2^machineNum*s; %numbe of possible decisions in the system
%cost parameters
CI = -5362;  %inspection cost
CS = 0;   %set up cost
CP = [-169,-397];  %preventive maintenance cost
CC = [-296,-775];  %corrective maintenance cost
PC = -2727;  %penalty cost

%find out the down condition for each component.
%C{1} means the first machine is down.
%S is the set of states where system is down.
C = cell(1,machineNum);
T = zeros(machineNum, 3^(machineNum-1)*s);
for i = 1:machineNum
    C{i} = [];
    for j = stateNum:-1:1
        if rem(j,states^(machineNum-i+1))==0
            C{i} = [C{i},j:-1:j-states^(machineNum-i)+1];
        end
    end
    T(i,:) = C{i};
end
U = zeros(1,stateNum);
for i = 1:stateNum
    U(i) = sum(T(:) == i);
end
threshold = 1;
S = find(U >= threshold);

%find out the repair action in the decisions for each device
%R{1} means the first machine is repaired in decision set R{1}.
R = cell(1,machineNum);
for i = 1:machineNum
    R{i} = [];
    for j = decisionNum:-1:1
        if rem(j,2^(machineNum-i+1))==0
            R{i}=[R{i},j:-1:j-2^(machineNum-i)+1];
        end
    end
end
             
%find out the inspect action in the condition
I = 1:(3^machineNum);

%B(i,j)the total cost of decision j under state i. B matrix.
Rall = zeros(machineNum,2^(machineNum-1)*s);
for i = 1:machineNum
    Rall(i,:) = R{i};
end
Rall = reshape(Rall,[1,machineNum*2^(machineNum-1)*s]);
[p,q]=hist(Rall,1:decisionNum);
[pi,qi]=hist(I,1:stateNum);
B = zeros(stateNum,decisionNum);
for i = 1:stateNum
    for j = 1:decisionNum
        cost = 0;
        if ismember(j,Rall)
            cost = CS;
        end
        for k = 1:machineNum
            if p(j)==k
                cost = cost + k*CP(k);
            end
            if ismember(j,R{k})&&ismember(i,C{k})
                cost = cost+CC(k)-CP(k);
            end
        end
        if ismember(i,S)
            cost = cost + PC;
        end
        for k = 1:machineNum
            if pi(i)==k
                cost = cost + k*CI;
            end
        end
        B(i,j)= cost;
    end
end

%check matrix P and B, here we used MDPtoolbox, which is a markov decision
%process box.
mdp_check(P,B)
[policy,average_reward] = mdp_relative_value_iteration(P,B,0.01,100);

%transfer the policy to a readable form.
poli = zeros(stateNum/s,machineNum+1);
for i = 1:(stateNum/s)
    k = machineNum+1;
    mo = policy(i)-1;
    while k > 0
        if k == 1
            poli(i,k) = rem(mo,s)+1;
            mo = floor(mo/s);
        else
            poli(i,k) = rem(mo,2);
            mo = floor(mo/2);
        end
        k = k - 1;
    end
end

%get the stationary disrbution
mu = get_stationary_distribution(mdp_computePpolicyPRpolicy(P,B,policy));

%draw the graph of the distribution
a = zeros(1,machineNum);
for j = 1:machineNum
    for i = C{j}
        a(j)=a(j)+mu(i);
    end
end

b = 0;
for i = S
    b = b + mu(i);
end
bar([a,b],0.2);
xlabel('system condition');ylabel('percentage of downtime in system condition');
        