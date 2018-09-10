__constant int N=24;
__constant int R=1088;
__constant int numwords=R/64;
__constant ulong RC[24]={
    0x0000000000000001,
    0x0000000000008082,
    0x800000000000808A,
    0x8000000080008000,
    0x000000000000808B,
    0x0000000080000001,
    0x8000000080008081,
    0x8000000000008009,
    0x000000000000008A,
    0x0000000000000088,
    0x0000000080008009,
    0x000000008000000A,
    0x000000008000808B,
    0x800000000000008B,
    0x8000000000008089,
    0x8000000000008003,
    0x8000000000008002,
    0x8000000000000080,
    0x000000000000800A,
    0x800000008000000A,
    0x8000000080008081,
    0x8000000000008080,
    0x0000000080000001,
    0x8000000080008008,
};
__constant uint r[5][5]={
    {0,36,3,41,18,},
    {1,44,10,45,2,},
    {62,6,43,15,61,},
    {28,55,25,21,56,},
    {27,20,39,8,14,},
};

ulong rot(ulong W,unsigned int r){
    return (W<<r)|(W>>(64-r));

}

void Round1600(ulong A[5][5], ulong rc){
    ulong B[5][5],C[5],D[5];
    for (int x=0;x<5;x++){
        C[x] = A[x][0]^A[x][1]^A[x][2]^A[x][3]^A[x][4];
    }
    for (int x=0;x<5;x++){
        D[x]=C[(x+4)%5]^rot(C[(x+1)%5],1);
    }
    for (int x=0;x<5;x++){
        for (int y=0;y<5;y++){
            A[x][y]=A[x][y]^D[x];
    }}
    for (int x=0;x<5;x++){
        for (int y=0;y<5;y++){
            B[y][(2*x+3*y)%5]=rot(A[x][y],r[x][y]);
    }}
    for (int x=0;x<5;x++){
        for (int y=0;y<5;y++){
            A[x][y]=B[x][y]^((~B[(x+1)%5][y])&B[(x+2)%5][y]);
    }}
    A[0][0]^=rc;
}

void Keccak_1600f(ulong A[5][5]){
    for (int i=0;i<N;i++){
        Round1600(A,RC[i]);
    }
}

void u2ch(ulong a){
    ulong m=0x00000000000000ff;
    uchar s[32]= { a&m,
            (a>>8)&m,
            (a>>16)&m,
            (a>>24)&m,
            (a>>32)&m,
            (a>>40)&m,
            (a>>48)&m,
            (a>>56)&m,
            0x00,};
    for(int i=0;i<8;i++){
        printf("%0.2x",s[i]);
    }
}

void SHA3_256(uchar* M, uchar* H){
    uchar d = 0x06;
    ulong A[5][5]={
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
    };
    int i=0;
    int tmpi=0;
    while(M[i]!=0x00){
        tmpi=(i/8)%numwords;
        A[tmpi%5][tmpi/5]^=(ulong)M[i]<<(8*(i%8));
        i++;
        if (i%136==0){
            Keccak_1600f(A);
        }
    }
        tmpi=(i/8)%numwords;
    A[tmpi%5][tmpi/5]^=0x06UL<<(8*(i%8)); 
    i++;
    A[16%5][16/5]^=0x8000000000000000;
    Keccak_1600f(A);

    ulong m=0x00000000000000ff;
    
    
    for(int j=0;j<32;j++){
            H[j]=m&A[j/8][0]>>(8*(j%8));
    }

        
}

void copystate(ulong a[5][5], ulong b [5][5]){
    
    a[0][0]=b[0][0];
    a[0][1]=b[0][1];
    a[0][2]=b[0][2];
    a[0][3]=b[0][3];
    a[0][4]=b[0][4];
    
    a[1][0]=b[1][0];
    a[1][1]=b[1][1];
    a[1][2]=b[1][2];
    a[1][3]=b[1][3];
    a[1][4]=b[1][4];
    
    a[2][0]=b[2][0];
    a[2][1]=b[2][1];
    a[2][2]=b[2][2];
    a[2][3]=b[2][3];
    a[2][4]=b[2][4];
    
    a[3][0]=b[3][0];
    a[3][1]=b[3][1];
    a[3][2]=b[3][2];
    a[3][3]=b[3][3];
    a[3][4]=b[3][4];
    
    a[4][0]=b[4][0];
    a[4][1]=b[4][1];
    a[4][2]=b[4][2];
    a[4][3]=b[4][3];
    a[4][4]=b[4][4];
    
}


//public key 32byte, random 32byte
__kernel void keccak256(__global ulong * public, __global ulong * random, __global uchar * nonce, __global uchar * res, __global uint iter){
    

    ulong m=0x00000000000000ff;
    uchar ch0,ch1;
    ulong PreA[5][5]={
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
    };

    ulong A[5][5]={
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
    };
    
    ulong BestPreA[5][5]={
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
    };

    ulong BestA[5][5]={
        {0xffffffffffffffff,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
        {0,0,0,0,0,},
    };

        uint global_id=get_global_id(0);

    PreA[0][0]=public[0];
    PreA[1][0]=public[1];
    PreA[2][0]=public[2];
    PreA[3][0]=public[3];
    PreA[4][0]=random[0]+global_id;
    PreA[0][1]=random[1];
    PreA[1][1]=random[2];
    PreA[2][1]=random[3];
    PreA[3][1]=0x06;
    PreA[1][3]=0x8000000000000000;
    


    int k,x,y,j;


    ulong B[5][5],C[5],D[5];
    
    for (ulong i=0;i<iter;i++){
        copystate(A,PreA);
        
        for (k=0;k<N;k++){      
            for (x=0;x<5;x++){
                C[x] = A[x][0]^A[x][1]^A[x][2]^A[x][3]^A[x][4];
            }
            for (x=0;x<5;x++){
                D[x]=C[(x+4)%5]^rot(C[(x+1)%5],1);
            }
            for (x=0;x<5;x++){
                for (y=0;y<5;y++){
                    A[x][y]=A[x][y]^D[x];
            }}
            for (x=0;x<5;x++){
                for (y=0;y<5;y++){
                    B[y][(2*x+3*y)%5]=rot(A[x][y],r[x][y]);
            }}
            for (x=0;x<5;x++){
                for (y=0;y<5;y++){
                    A[x][y]=B[x][y]^((~B[(x+1)%5][y])&B[(x+2)%5][y]);
            }}

            A[0][0]^=RC[k];
        }
        
        for(j = 0; j < 32; j++){

            ch1 = m & A[j / 8][0] >> (8 * (j % 8));
            ch0 = m & BestA[j / 8][0] >> (8 * (j % 8));
            
            if(ch0 < ch1){
                break;
            }
            if(ch0 > ch1){
                copystate(BestA, A);
                copystate(BestPreA, PreA);
                break;
            }

        }

        PreA[0][1]++;

        }
      
        for(int j=0;j<32;j++){
            nonce[global_id*32+j]=(m&BestPreA[(4+j/8)%5][(4+j/8)/5]>>(8*(j%8)))%256;
        }

        
        for(int j=0;j<32;j++){
            res[global_id*32+j]=(m&BestA[(j/8)%5][(j/8)/5]>>(8*(j%8)))%256;
        }
        random[3]++;
        
    
}
