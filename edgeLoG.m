function J = edgeLoG(I, n, tre);
    s = n/5;
    s = 2.0 * s * s;
    H = double(zeros(n, n));
    r = (n-1) / 2;
    %sum = 0.0;
    %for i = 1:n
    %    x = i - 1 - r;
    %    for j = 1:n
    %        y = j - 1 - r;
    %        H(i, j) = 1/(s*pi) * exp(-(x*x+y*y)/s);
    %        sum = sum + H(i, j);
    %    end
    %end
    X = repmat([-r:r], n, 1);
    Y = repmat(transpose([-r:r]), 1, n);
    H = 1/(s*pi) * exp(-(X.*X+Y.*Y)/s);
    H = H / sum(sum(H));
    %for i = 1:n
    %    for j = 1:n
    %        H(i, j) = H(i, j) / sum;
    %    end
    %end
    L = [0 1 0; 1 -4 1; 0 1 0];
    H = (convn(double(H), double(L), "same"));
    J = uint8(convn(double(I), double(H), "same")) > tre;
end