create database atv2209
go
use atv2209
go

/* Criação de tabelas */
create table Produto(
Id int identity primary key,
Nome varchar(100) not null
)
go

create table Estoque(
Id int identity primary key,
Quantidade int not null check(Quantidade>=0),
IdProduto int foreign key references Produto(Id)
)
go

create table Venda(
Id int identity primary key,
Quantidade int not null check(Quantidade>0),
Valor decimal not null,
Data date not null,
IdProduto int foreign key references Produto(Id)
)
go

create table Log(
Id int identity primary key,
Data date not null,
Tabela varchar(50) not null,
Comando varchar(200) not null,
Message varchar(200) not null,
Severity int not null
)
go

/* Trigger para auto add estoque */
create trigger addStock
on Produto
after insert
as
begin
	declare @Id int
	declare cursorAddStock cursor for
		select Id from Inserted
	open cursorAddStock

	fetch next from cursorAddStock
		into @Id

	while @@FETCH_STATUS=0
	begin
		insert into Estoque values
			(0, @Id)

		fetch next from cursorAddStock
			into @Id
	end
	close cursorAddStock
	deallocate cursorAddStock
end
go

/* Trigger para redução de estoque */
create trigger reduceStock
on Venda
after insert
as
begin
	declare @ProductId int
	declare @Quantity int

	declare insertCursor cursor for
		select IdProduto, Quantidade 
		from inserted
	open insertCursor

	fetch next from insertCursor 
		into @ProductId, @Quantity
		
	while @@FETCH_STATUS=0
	begin
		update Estoque
			set Quantidade = Quantidade - @Quantity
			where IdProduto = @ProductId
		fetch next from insertCursor 
			into @ProductId, @Quantity	
	end

	close insertCursor
	deallocate insertCursor
end
go

/* Trigger para delete de stock quando delete Product */
create trigger deleteProductStock
on Produto
instead of delete
as
begin
	declare @ProductId int 
	
	declare deleteCursor cursor for
		select Id
		from deleted
	open deleteCursor

	fetch next from deleteCursor
		into @ProductId

	while @@FETCH_STATUS = 0
	begin
		delete Estoque
			where IdProduto = @ProductId

		delete Venda
			where IdProduto = @ProductId

		delete Produto
			where Id = @ProductId

		fetch next from deleteCursor
			into @ProductId
	end

	close deleteCursor
	deallocate deleteCursor
end
go


/* Procedure para registro de vendas */
create procedure registerSell
@ProductId int,
@Quantity int, 
@Value decimal 
as 
begin
	begin transaction
	begin try
		insert into Venda values
			(@Quantity, @Value, GETDATE(), @ProductId)
	end try
	begin catch
		rollback transaction
		insert into Log values 
			(GETDATE(), 'registerSell', 'insert', ERROR_MESSAGE(), ERROR_SEVERITY())
		print('ERROR: ' + ERROR_MESSAGE())
	end catch
	if @@TRANCOUNT>0
		commit transaction
end
go

/* Procedure para registo de produto */
create procedure registerProduct
@Name varchar(100)
as
begin
	begin transaction
	begin try
		insert into Produto values
			(@Name)
	end try
	begin catch
		rollback transaction
		insert into Log values
			(GETDATE(), 'registerProduct', 'insert', ERROR_MESSAGE(), ERROR_SEVERITY())
		print('ERROR: ' + ERROR_MESSAGE())
	end catch
	if @@TRANCOUNT>0
		commit transaction
end
go

/* Procedure para update de produto */
create procedure updateProduct
@Id int,
@NewName varchar(100)
as
begin
	begin transaction
	begin try
		update Produto 
			set Nome = @Newname 
			where Id = @Id
	end try
	begin catch
		rollback transaction
		insert into Log values
			(GETDATE(), 'updateProduct', 'update', ERROR_MESSAGE(), ERROR_SEVERITY())
		print('ERROR: ' + ERROR_MESSAGE())
	end catch
	if @@TRANCOUNT>0
		commit transaction
end
go

/* Procedure para delete de produto */
create procedure deleteProduct
@Id int
as
begin
	begin transaction
	begin try
		delete Produto
			where Id = @Id
	end try
	begin catch
		rollback transaction
		insert into Log values
			(GETDATE(), 'deleteProduct', 'delete', ERROR_MESSAGE(), ERROR_SEVERITY())
		print('ERROR: ' + ERROR_MESSAGE())
	end catch
	if @@TRANCOUNT>0
		commit transaction
end
go

/* Procedure para registro de estoque */
create procedure registerStock
@ProductId int,
@Quantity int
as
begin
	begin transaction
	begin try
		insert into Estoque values
			(@Quantity, @ProductId)
	end try
	begin catch
		rollback transaction
		insert into Log values
			(GETDATE(), 'registerStock', 'insert', ERROR_MESSAGE(), ERROR_SEVERITY())
		print('ERROR: ' + ERROR_MESSAGE())
	end catch
	if @@TRANCOUNT>0
		commit transaction
end
go

/* Procedure para update de estoque */
create procedure updateStock
@Id int,
@Quantity int
as
begin
	begin transaction
	begin try
		update Estoque 
			set Quantidade = @Quantity
			where Id = @Id
	end try
	begin catch
		rollback transaction
		insert into Log values
			(GETDATE(), 'updateStock', 'update', ERROR_MESSAGE(), ERROR_SEVERITY())
		print('Error: ' + ERROR_MESSAGE())
	end catch 
	if @@TRANCOUNT>0
		commit transaction
end
go

/* Procedure para delete de estoque */
create procedure deleteStock
@Id int
as
begin
	begin transaction
	begin try
		delete Estoque
			where Id = @Id
	end try
	begin catch
		rollback transaction
		insert into Log values
			(GETDATE(), 'deleteStock', 'delete', ERROR_MESSAGE(), ERROR_SEVERITY())
		print('Error: ' + ERROR_MESSAGE())
	end catch
	if @@TRANCOUNT>0
		commit transaction
end
go

insert into Produto values
('Vassoura'),
('Pneu'),
('Fini'),
('Notebook');
go
update Estoque
	set Quantidade = 5 * Id
go

exec registerSell 1, 6, 60
exec registerProduct 'Camisa'
exec updateProduct 5, 'Camiseta'
exec deleteProduct 5

select * from Produto
select * from Estoque

select * from Venda
select * from Log