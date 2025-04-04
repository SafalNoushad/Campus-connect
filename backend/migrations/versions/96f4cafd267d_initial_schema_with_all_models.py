"""Initial schema with all models

Revision ID: 96f4cafd267d
Revises: 
Create Date: 2025-03-30 23:58:43.396428

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '96f4cafd267d'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('departments',
    sa.Column('departmentcode', sa.String(length=10), nullable=False),
    sa.Column('departmentname', sa.String(length=100), nullable=False),
    sa.PrimaryKeyConstraint('departmentcode')
    )
    op.create_table('users',
    sa.Column('admission_number', sa.String(length=50), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.Column('email', sa.String(length=255), nullable=False),
    sa.Column('password', sa.String(length=255), nullable=False),
    sa.Column('role', sa.Enum('admin', 'hod', 'staff', 'student', name='user_roles'), nullable=False),
    sa.Column('username', sa.String(length=100), nullable=False),
    sa.Column('departmentcode', sa.String(length=10), nullable=False),
    sa.Column('semester', sa.String(length=2), nullable=True),
    sa.Column('phone_number', sa.String(length=15), nullable=True),
    sa.Column('batch', sa.String(length=10), nullable=True),
    sa.PrimaryKeyConstraint('admission_number'),
    sa.UniqueConstraint('email')
    )
    op.create_table('notes',
    sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('semester', sa.String(length=2), nullable=False),
    sa.Column('filename', sa.String(length=255), nullable=False),
    sa.Column('departmentcode', sa.String(length=10), nullable=False),
    sa.Column('uploaded_at', sa.DateTime(), nullable=False),
    sa.ForeignKeyConstraint(['departmentcode'], ['departments.departmentcode'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('subjects',
    sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('semester', sa.String(length=2), nullable=False),
    sa.Column('subject_code', sa.String(length=10), nullable=False),
    sa.Column('subject_name', sa.String(length=100), nullable=False),
    sa.Column('credits', sa.Integer(), nullable=False),
    sa.Column('departmentcode', sa.String(length=10), nullable=False),
    sa.ForeignKeyConstraint(['departmentcode'], ['departments.departmentcode'], ),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('subject_code')
    )
    op.create_table('timetables',
    sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('semester', sa.String(length=2), nullable=False),
    sa.Column('filename', sa.String(length=255), nullable=False),
    sa.Column('departmentcode', sa.String(length=10), nullable=False),
    sa.Column('uploaded_at', sa.DateTime(), nullable=False),
    sa.ForeignKeyConstraint(['departmentcode'], ['departments.departmentcode'], ),
    sa.PrimaryKeyConstraint('id')
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('timetables')
    op.drop_table('subjects')
    op.drop_table('notes')
    op.drop_table('users')
    op.drop_table('departments')
    # ### end Alembic commands ###
