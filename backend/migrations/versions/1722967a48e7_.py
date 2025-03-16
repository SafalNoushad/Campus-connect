"""empty message

Revision ID: 1722967a48e7
Revises: b74fc924dd75
Create Date: 2025-03-10 05:30:06.447951

"""
from alembic import op
import sqlalchemy as sa

revision = '1722967a48e7'
down_revision = 'b74fc924dd75'
branch_labels = None
depends_on = None

def upgrade():
    with op.batch_alter_table('users', schema=None) as batch_op:
        # Only add columns if they don’t exist (manual check needed)
        batch_op.add_column(sa.Column('phone_number', sa.String(length=20), nullable=True), insert_if_not_exists=True)
        batch_op.add_column(sa.Column('departmentcode', sa.String(length=10), nullable=False), insert_if_not_exists=True)
        # Skip 'batch' since it exists
        # batch_op.add_column(sa.Column('batch', sa.String(length=9), nullable=True))

def downgrade():
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('phone_number')
        batch_op.drop_column('departmentcode')
        # Don’t drop 'batch' to preserve data