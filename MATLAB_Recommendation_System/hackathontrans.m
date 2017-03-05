function transys = hackathontrans(A,s)
S = 1;
n = size(A,2);
J = cell(1,n);
for i = 1:n
    J{i} = getTrans(A{i});
end
for i =1:n
    S = superkron(S,J{i});
end
D = superkron(eye((s-1),s),S(:,:,1));
D = repmat(D,[1,1,2^n*s]);
h(1,:,:) = eye(s,s);
transy = superkron(h,S);
transys = [transy;D];

end


%get transition matrix for one unit
function trans = getTrans(A)
B = [A(1,:);
    A(1,:);
    A(1,:)];
C = zeros(3,3,2);
C(:,:,1)=A;
C(:,:,2)=B;
trans = C;
end