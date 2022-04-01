function J = edgeLoG(I, n, tre);
    s = n/5;
    H = double(zeros(n, n));
    r = (n-1) / 2;
    X = repmat([-r:r], n, 1);
    Y = repmat(transpose([-r:r]), 1, n);
    t = -(X.*X+Y.*Y)/(2.0*s*s);
    H = (-1/(pi*s*s*s*s)) * ((1+t) .* exp(t));
    H = H - mean2(H);
    %H = fspecial('log', n, s)
    J = uint8(convn(double(I), double(H), "same")) > tre;
end